//
//  PriceInfo.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-17.
//

import Foundation

public typealias CurrencyCode = String
public typealias Price = Decimal

/// Determines how to calculate related price information.
public enum PriceType: Int, Codable {
  /// The un-taxed per-item price.
  case perUnitBeforeTax
  /// The taxed per-item price, this is rarely specified by end users directly because tax price usually won't directly applied to unit price,
  case perUnitAfterTax
  /// The un-taxed sum price (unit price x quantity).
  case sumBeforeTax
  /// The taxed sum (unit price x quantity + tax) price.
  case sumAfterTax
}


/** Contains information that can be used to describe the anatomy of a price.
 
 ``PriceInfo`` Can be used to calculate related tax information. However, these information may not always be meaningful,
 depending on its ``priceType``:
 - if the price type is un-taxed unit price, then all costs can be correctly calculated and rounded;
 - if the price type is un-taxed price sum, all related tax costs and totals can be calculated and rounded correctly, but it's unit price
 may only be an estimate and lose decimal places.
 - If the price type is a taxed unit price/price sum, then it's only possible to estimate all other costs related information due to price
 and tax rounding rules.
 
*/
public struct PriceInfo: Codable, Equatable {
  public var price: Price
  public var priceType: PriceType
  /// If specified, the app will use it as after tax total. This value will not be rounded by the app.
  public var explicitAfterTaxTotal: Price?
  public var quantity: ItemQuantity = 0
  
  public var regularTaxItems: [RateTaxItem] = []
  public var compoundTaxItems: [RateTaxItem] = []
  public var fixedAmountTaxItems: [FixedAmountItem] = []
  // TODO: discount? after tax or before tax?
  
  public init(price: Price, priceType: PriceType,
              explicitAfterTaxTotal: Price? = nil,
              quantity: ItemQuantity = 0,
              regularTaxItems: [RateTaxItem] = [],
              compoundTaxItems: [RateTaxItem] = [],
              fixedAmountTaxItems: [FixedAmountItem] = []) {
    self.price = price
    self.priceType = priceType
    self.quantity = quantity
    self.explicitAfterTaxTotal = explicitAfterTaxTotal
    self.regularTaxItems = regularTaxItems
    self.compoundTaxItems = compoundTaxItems
    self.fixedAmountTaxItems = fixedAmountTaxItems
  }
  
  var itemQuantity: Decimal {
    Decimal(quantity)
  }
  
  public static func fresh() -> PriceInfo {
    .init(price: 0.0, priceType: .perUnitBeforeTax)
  }
  
  public var canOnlyCalculateAveragePrice: Bool {
    priceType == .sumBeforeTax || priceType == .sumAfterTax
  }
  
  /// The price before tax can only be inferred if the ``PriceInfo/priceType`` indicate the price is after tax value.
  public var canOnlyInferPriceBeforeTax: Bool {
    priceType == .sumAfterTax || priceType == .perUnitAfterTax
  }
  
  /** The total price after tax.
   */
  public func totalAfterTax(taxItemRounding: RoundingRule,
                            itemTotalRounding: RoundingRule) -> Price {
    if let explicitAfterTaxTotal {
      return explicitAfterTaxTotal
    }
    let total: Price
    switch priceType {
      case .perUnitAfterTax:
        total = price * itemQuantity
      case .perUnitBeforeTax:
        total = totalBeforeTax + allTaxSum(roundedWith: taxItemRounding)
      case .sumBeforeTax:
        total = price + allTaxSum(roundedWith: taxItemRounding)
      case .sumAfterTax:
        total = price
    }
    return total.rounded(using: itemTotalRounding)
  }
  
  /** Calculates the un-taxed total.
   
   The total price before tax is typically the sum of the individual item prices multiplied by their quantities. This is usually a whole number or a number with fixed decimal places (for currencies like the USD, EUR, etc.) because item prices and quantities are typically set in such a way that they don't produce more decimal places when multiplied. As a result, the total before tax is usually not rounded, because there's no need to do so.
   */
  public var totalBeforeTax: Decimal {
    switch priceType {
      case .perUnitBeforeTax:
        return price * itemQuantity
      case .sumBeforeTax: // may lose precision due to division and rounding
        return price
      case .perUnitAfterTax: // only estimate
        return (price / combinedTaxRate) * itemQuantity
      case .sumAfterTax: // only estimate
        return price / combinedTaxRate
    }
  }
  
  func totalAfterRegularTax(roundedWith taxItemRounding: RoundingRule) -> Price {
    totalBeforeTax + regularTaxSum(roundedWith: taxItemRounding)
  }
  
  public func regularTaxSum(roundedWith taxItemRounding: RoundingRule) -> Price {
    return regularTaxItems
      .reduce(0) {
        $0 + $1.taxCost(of: totalBeforeTax).rounded(using: taxItemRounding)
      }
  }
  
  public func compoundTaxSum(roundedWith taxItemRounding: RoundingRule) -> Price {
    let cachedTotalAfterRegularTax = totalAfterRegularTax(roundedWith: taxItemRounding)
    return compoundTaxItems.reduce(0, { $0 + $1.taxCost(of: cachedTotalAfterRegularTax).rounded(using: taxItemRounding) })
  }
  
  /// The sum of all fixed tax items.
  ///
  /// Fixed amount tax doesn't need to be rounded.
  public var fixedTaxSum: Price {
    fixedAmountTaxItems.reduce(0) { $0 + $1.amount }
  }
  
  public func allTaxSum(roundedWith taxItemRounding: RoundingRule) -> Price {
    regularTaxSum(roundedWith: taxItemRounding)
    + compoundTaxSum(roundedWith: taxItemRounding)
    + fixedTaxSum
  }
    
  /// Calculate the compound tax rate that can be applied directly on the un-taxed price to calculate the tax amount.
  ///
  /// This method does not consider rounding, so it won't be able to generate precise rounding
  private func compoundTaxRateForPriceBeforeTax(for rateTaxItem: RateTaxItem) -> Decimal {
    /// combined regular tax rate x combined tax rate
    (1 + (regularTaxItems.reduce(0, { $0 + $1.rate }))) * rateTaxItem.rate
  }
  
  private var combinedTaxRate: Decimal {
    let combinedRegularTaxRate: Decimal = regularTaxItems.reduce(0, { $0 + $1.rate })
    let rate = compoundTaxItems.reduce((1 + combinedRegularTaxRate)) { partialResult, compoundTaxItem in
      partialResult + (1 + combinedRegularTaxRate) * compoundTaxItem.rate
    }
    return rate
  }
  
  /// The before tax price.
  public var pricePerUnitBeforeTax: Price {
    switch priceType {
      case .perUnitBeforeTax:
        return price
      case .sumBeforeTax:
        // estimated price per unit
        return price / itemQuantity
      case .perUnitAfterTax:
        /// We can only provide inferred price, based on after tax price and tax items,
        let combinedRegularTaxRate: Decimal = regularTaxItems.reduce(0, { $0 + $1.rate })
        let rate = compoundTaxItems.reduce((1 + combinedRegularTaxRate)) { partialResult, compoundTaxItem in
          partialResult + (1 + combinedRegularTaxRate) * compoundTaxItem.rate
        }
        // after tax price / rate = estimated before tax price
        return (price - fixedTaxSum) / rate
      case .sumAfterTax:
        /// We can only provide inferred price, based on after tax price and tax items,
        // after tax price / rate = estimated before tax price
        return (price - fixedTaxSum) / combinedTaxRate / itemQuantity
    }
  }
  
  /// Returns the price per unit after tax.
  ///
  public func pricePerUnitAfterTax(taxItemRounding: RoundingRule,
                                  totalRounding: RoundingRule) -> Price {
    if priceType == .perUnitAfterTax { return price } else {
      if !itemQuantity.isZero {
        return totalAfterTax(taxItemRounding: taxItemRounding, itemTotalRounding: totalRounding) / itemQuantity
      } else {
        return 0
      }
    }
  }
}

extension PriceInfo {
  /// Remove all tax item with empty name and value, this is useful when user adds redundant tax items without entering any value
  var compacted: PriceInfo {
    var copied = self
    copied.regularTaxItems = copied.regularTaxItems.filter { item in
      !item.rate.isZero || !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    copied.compoundTaxItems = copied.compoundTaxItems.filter { item in
      !item.rate.isZero || !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    copied.fixedAmountTaxItems = copied.fixedAmountTaxItems.filter { item in
      !item.amount.isZero || !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    return copied
  }
}

public struct RateTaxItem: Codable, Identifiable, Equatable {
  public var id = UUID()
  public var name: String
  public var rate: Decimal
  
  public static func fresh() -> RateTaxItem {
    RateTaxItem(name: "", rate: 0.0)
  }
  
  public func taxCost(of price: Price) -> Price {
    price * rate
  }
}

public struct FixedAmountItem: Codable, Identifiable, Equatable {
  public var id = UUID()
  public var name: String
  public var amount: Price
  
  static func fresh() -> FixedAmountItem {
    FixedAmountItem(name: "", amount: 0.0)
  }
}
