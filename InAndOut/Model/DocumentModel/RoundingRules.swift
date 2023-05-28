//
//  RoundingRules.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-19.
//

import Foundation


public struct RoundingRuleSet: Codable {
  
  /// Applies to each individual tax item. This rounding rule only applies to calculation process where price before tax aren't inferred.
  /// That is, if the price type is an after tax value, then the rounding won't be applied when inferring the price before tax using tax items.
  public var taxItemRule = RoundingRule.defaultRoundingRule()
  public var itemTotalRule = RoundingRule.defaultRoundingRule()
  public var transactionTotalRule = RoundingRule.defaultRoundingRule()
  
  init(defaultFor currency: CurrencyCode) {
    let defaultRuleForSpecifiedCurrency = RoundingRule.defaultRoundingRule(for: currency)
    self.taxItemRule = defaultRuleForSpecifiedCurrency
    self.itemTotalRule = defaultRuleForSpecifiedCurrency
    self.transactionTotalRule = defaultRuleForSpecifiedCurrency
  }
  
  init(taxAmountRule: RoundingRule = RoundingRule.defaultRoundingRule(),
       itemTotalRule: RoundingRule = RoundingRule.defaultRoundingRule(),
       transactionTotalRule: RoundingRule = RoundingRule.defaultRoundingRule()) {
    self.taxItemRule = taxAmountRule
    self.itemTotalRule = itemTotalRule
    self.transactionTotalRule = transactionTotalRule
  }
}

public struct RoundingRule: Codable, CustomDebugStringConvertible {
  public var scale: Int
  public var mode: RoundingMode
  
  /// The default rounding rule uses the default scale used by the currency currency code
  static func defaultRoundingRule(for currencyIdentifier: String = Global.systemCurrentCurrencyCode) -> RoundingRule {
    RoundingRule(scale: defaultScale(for: currencyIdentifier), mode: .plain)
  }
  
  private static func defaultScale(for currencyCode: String) -> Int {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .currency
    numberFormatter.currencyCode = currencyCode
    return numberFormatter.maximumFractionDigits
  }
  
  var description: String {
    String(localized: "\(mode.description), \(scale) Decimal Places")
  }
  
  public var debugDescription: String {
    "Rounding: (\(mode.description), scale: \(scale))"
  }
}

extension Decimal {
  
  public func rounded(using rule: RoundingRule) -> Decimal {
      return self.rounded(rule.scale, rule.mode.nsDecimalRoundingMode)
  }
}

public enum RoundingMode: Codable, CaseIterable, CustomStringConvertible {
  /// aka half-up
  case plain
  case up
  /// aka half-to-even
  case bankers
  case down
  
  public var description: String {
    switch self {
      case .plain:
        return String(localized: "Half-Up", comment: "Abbreviated title of the half-up rounding method")
      case .bankers:
        return String(localized: "Banker's", comment: "Abbreviated title of the Banker's Rounding method")
      case .up:
        return String(localized: "Up", comment: "Abbreviated title of the Up Rounding method")
      case .down:
        return String(localized: "Down", comment: "Abbreviated title of the Down Rounding method")
    }
  }
  
  public var nsDecimalRoundingMode: NSDecimalNumber.RoundingMode {
    switch self {
      case .up:
        return .up
      case .plain:
        return .plain
      case .bankers:
        return .bankers
      case .down:
        return .down
    }
  }
}

public enum RoundingLevel: Codable {
  
  case priceBeforeTax
  case priceAfterTax
  /// Every tax item will be rounded
  case taxAmount
  case itemTotal
  case transactionTotal
}
