//
//  Globals.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-09.
//

import Foundation
import SwiftUI

struct Global {
  static let timesSymbol = "×"
  static let appName = "In&Out"
  static let transactionIDHighlightColor: SwiftUI.Color = .accentColor.opacity(0.8)
  static var currentCurrencyCode: String {
    Locale.current.currency?.identifier ?? Locale.Currency(stringLiteral: "USD").identifier
  }
}
