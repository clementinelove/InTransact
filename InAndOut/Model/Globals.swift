//
//  Globals.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-09.
//

import Foundation
import SwiftUI

struct Global {
  // This is the hard coded accent color
  static let tint = Color(red: 0.310, green: 0.635, blue: 0.451)
  static let subsystem = "cc.clems.InTransact"
  static let timesSymbol = "×"
  static let transactionIDHighlightColor: SwiftUI.Color = .accentColor.opacity(0.8)
  static var systemCurrentCurrencyCode: String {
    Locale.current.currency?.identifier ?? Locale.Currency(stringLiteral: "USD").identifier
  }
}
