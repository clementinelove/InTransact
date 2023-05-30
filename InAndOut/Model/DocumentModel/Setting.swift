//
//  Setting.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-17.
//
import Foundation

struct Setting: Codable, CustomDebugStringConvertible {
  var currencyIdentifier: String = Global.systemCurrentCurrencyCode
  // Rounding Rule Settings for each rounding level
  var roundingRules: RoundingRuleSet = RoundingRuleSet(defaultFor: Global.systemCurrentCurrencyCode)
//  var defaultKeeperName: String? = nil
//  func transactionTemplate() -> Transaction {
//    
//  }
//  var itemTransactionTemplate() -> ItemTransaction {
//    var fresh = ItemTransaction.fresh()
//  }
  
  mutating func resetRoundingToCurrencyDefault() {
    roundingRules = RoundingRuleSet(defaultFor: currencyIdentifier)
  }
  
  var debugDescription: String {
    "(Settings – \(currencyIdentifier), taxRounding: \(roundingRules.taxItemRule), itemSubtotalRounding: \(roundingRules.itemSubtotalRule), transactionTotalRounding: \(roundingRules.transactionTotalRule))"
  }
}
