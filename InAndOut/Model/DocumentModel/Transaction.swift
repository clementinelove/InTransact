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
  
  /// Total of the whole transaction is the sum of every item transaction
  public func total(roundingRules: RoundingRuleSet) -> Decimal {
    var total: Decimal = 0
    for subtransaction in subtransactions {
      let subtotal = subtransaction.priceInfo.totalAfterTax(taxItemRounding: roundingRules.taxItemRule,
                                                            totalRounding: roundingRules.itemTotalRule)
      total += subtotal
    }
    return total.rounded(using: roundingRules.transactionTotalRule)
  }
}

struct ContactInfo: Codable {
  var name: String?
  var phone: String?
  var emailAddress: String?
  var location: String?
}

