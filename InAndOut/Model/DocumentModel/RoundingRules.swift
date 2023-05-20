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
  
  public init(taxAmountRule: RoundingRule = RoundingRule.defaultRoundingRule(),
              itemTotalRule: RoundingRule = RoundingRule.defaultRoundingRule(),
              transactionTotalRule: RoundingRule = RoundingRule.defaultRoundingRule()) {
    self.taxItemRule = taxAmountRule
    self.itemTotalRule = itemTotalRule
    self.transactionTotalRule = transactionTotalRule
  }
}

public struct RoundingRule: Codable {
  public var scale: Int
  public var mode: RoundingMode
  
  public static func defaultRoundingRule() -> RoundingRule {
    RoundingRule(scale: defaultScale(for: Global.currentCurrencyCode), mode: .plain)
  }
  
  private static func defaultScale(for currencyCode: String) -> Int {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .currency
    numberFormatter.currencyCode = currencyCode
    return numberFormatter.maximumFractionDigits
  }
}

extension Decimal {
  
  public func rounded(using rule: RoundingRule? = nil) -> Decimal {
    if let rule {
      return self.rounded(rule.scale, rule.mode.nsDecimalRoundingMode)
    } else {
      return self
    }
  }
}

public enum RoundingMode: Codable {
  case up
  /// aka half-up
  case plain
  case bankers
  case down
  
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
