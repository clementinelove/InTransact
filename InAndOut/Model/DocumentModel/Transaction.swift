//
//  Transaction.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-17.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import NTPlatformKit

public typealias ItemQuantity = UInt32

//extension UTType {
//  static var transaction: UTType = UTType(exportedAs: "com..transaction")
//  static var itemTransaction: UTType = UTType(exportedAs: "com.inandout.transaction.item")
//}

enum TransactionType: Int, Codable, CaseIterable, CustomStringConvertible {
  case itemsIn
  case itemsOut
  
  var description: String {
    switch self {
      case .itemsIn: return String(localized: "Items In")
      case .itemsOut: return String(localized: "Items Out")
    }
  }
}

struct Transaction: Identifiable, Codable, Hashable {
  typealias ID = UUID
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: Transaction, rhs: Transaction) -> Bool {
    lhs.id == rhs.id
  }
  
  var id: ID = ID()
  var transactionType: TransactionType
  var transactionID: String
  var subtransactions: [ItemTransaction]
  // the entity refers to supplier in a purchase transaction, customer in sales transaction,
  var comment: String
  // The name of the person responsible for bookkepping this transaction
  var keeperName: String?
  var contact: ContactInfo?
  var date: Date
  var fixedCosts: [FixedAmountItem] = []
  
  init(id: ID = ID(),
       transactionType: TransactionType,
       transactionID: String,
       subtransactions: [ItemTransaction] = [],
       fixedCosts: [FixedAmountItem] = [],
       comment: String,
       keeperName: String? = nil,
       date: Date) {
    self.id = id
    self.transactionType = transactionType
    self.transactionID = transactionID
    self.subtransactions = subtransactions
    self.fixedCosts = fixedCosts
    self.comment = comment
    self.keeperName = keeperName
    self.date = date
  }
  
  static func fresh(type: TransactionType) -> Transaction {
    Transaction(transactionType: type, transactionID: "", subtransactions: [], comment: "", keeperName: "",
                date: Date.now)
  }
  
  public var itemNames: Set<String> {
    var itemNameSet = Set<String>()
    for subtransaction in subtransactions {
      if let itemName = subtransaction.itemName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
        itemNameSet.insert(itemName)
      }
    }
    return itemNameSet
  }
  
  public var itemAndVariantNames: Set<String> {
    var itemNameSet = Set<String>()
    for subtransaction in subtransactions {
      itemNameSet.insert("\(subtransaction.itemName) \(subtransaction.variant ?? "")")
    }
    return itemNameSet
  }
  
  /// The total of this transaction before tax
  public func subtotal() -> Decimal {
    subtransactions.reduce(0, { $0 + $1.priceInfo.totalBeforeTax })
  }
  
  /// Total of the whole transaction is the sum of every item transaction
  public func total(roundingRules: RoundingRuleSet) -> Decimal {
    var total: Decimal = 0
    for subtransaction in subtransactions {
      let subtotal = subtransaction.priceInfo.totalAfterTax(taxItemRounding: roundingRules.taxItemRule,
                                                            itemTotalRounding: roundingRules.itemTotalRule)
      total += subtotal
    }
    total += fixedCosts.reduce(0) { $0 + $1.amount }
    return total.rounded(using: roundingRules.transactionTotalRule)
  }
  
  /// Get the sum of all shared tax items' costs in all subtransactions. Returns `nil` if any transactions doesn't share same tax items.
  public func sharedTaxInfo(taxRoundingRule: RoundingRule) -> (regular: [RateTaxItem: Decimal],
                                                               compound: [RateTaxItem: Decimal],
                                                               fixed: [FixedAmountItem: Decimal])? {
    guard let firstItem = subtransactions.first else { return nil }
    let regularTaxItems = Set(firstItem.priceInfo.regularTaxItems)
    let compoundTaxItems = Set(firstItem.priceInfo.compoundTaxItems)
    let fixedTaxItems = Set(firstItem.priceInfo.fixedAmountTaxItems)
    
    // TaxName -> Total
    var regularTaxTotals: [RateTaxItem: Decimal] = [ : ]
    regularTaxItems.forEach { taxItem in
      regularTaxTotals[taxItem] = 0
    }
    var compoundTaxTotals: [RateTaxItem: Decimal] = [ : ]
    compoundTaxItems.forEach { taxItem in
      compoundTaxTotals[taxItem] = 0
    }
    var fixedTaxTotals: [FixedAmountItem: Decimal] = [ : ]
    fixedTaxItems.forEach { taxItem in
      fixedTaxTotals[taxItem] = 0
    }
    for subtransaction in subtransactions {
      if regularTaxItems == Set(subtransaction.priceInfo.regularTaxItems) &&
          compoundTaxItems == Set(subtransaction.priceInfo.compoundTaxItems) &&
          fixedTaxItems == Set(subtransaction.priceInfo.fixedAmountTaxItems) {
        regularTaxItems.forEach { taxItem in
          regularTaxTotals[taxItem]! += taxItem.taxCost(of: subtransaction.priceInfo.totalBeforeTax, rounding: taxRoundingRule)
        }
        compoundTaxItems.forEach { taxItem in
          compoundTaxTotals[taxItem]! += taxItem.taxCost(of: subtransaction.priceInfo.totalAfterRegularTax(taxItemRounding: taxRoundingRule),
                                                            rounding: taxRoundingRule)
        }
        fixedTaxItems.forEach { taxItem in
          fixedTaxTotals[taxItem]! += taxItem.amount
        }
      } else {
        return nil
      }
    }
    return (regular: regularTaxTotals,
            compound: compoundTaxTotals,
            fixed: fixedTaxTotals)
  }
}

struct ContactInfo: Codable {
  var name: String?
  var phone: String?
  var emailAddress: String?
  var location: String?
}

