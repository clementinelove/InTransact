//
//  Formatters.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-09.
//

import Foundation

let taxRateFormatter: NumberFormatter = {
  let n = NumberFormatter()
  n.numberStyle = .percent
  n.maximumFractionDigits = 5
  n.maximum = 1
  n.minimum = 0
  return n
}()

let quantityFormatter: NumberFormatter = {
  let f = NumberFormatter()
  f.numberStyle = .none
  f.maximum = NSNumber(value: ItemQuantity.max)
  f.minimum = 0
  
  return f
}()

let priceFormatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.minimum = 0
  formatter.numberStyle = .decimal
  
  return formatter
}()

func formattedPrice(_ total: Decimal?) -> String? {
  guard let total else { return nil }
  let nsTotal = NSDecimalNumber(decimal: total)
  return priceFormatter.string(from: nsTotal)
}

let transactionDateFormatter: DateFormatter = {
  let f = DateFormatter()
  f.dateStyle = .medium
  f.timeStyle = .short
  f.doesRelativeDateFormatting = true
  return f
}()
