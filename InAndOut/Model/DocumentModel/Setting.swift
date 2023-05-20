//
//  Setting.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-17.
//
import Foundation

struct Setting: Codable {
  var forceItemID: Bool = false
  var currencyIdentifier: String = Global.currentCurrencyCode
  var alwaysGenerateTransactionID: Bool = true
  /// Also know as: number of digits after decimal delimiter.
  var roundingPrecision: UInt16 = 0
  var roundingMethod: RoundingMode = .bankers
  
  // Rounding Rule Settings for each rounding level
  var roundingRules: RoundingRuleSet = RoundingRuleSet()
}
