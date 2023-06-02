//
//  Globals.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-09.
//

import Foundation
import SwiftUI

struct Global {
  static let subsystem = "cc.clems.InTransact"
  static let timesSymbol = "×"
  static let transactionIDHighlightColor: SwiftUI.Color = .accentColor.opacity(0.8)
  static var systemCurrentCurrencyCode: String {
    Locale.current.currency?.identifier ?? Locale.Currency(stringLiteral: "USD").identifier
  }
}
