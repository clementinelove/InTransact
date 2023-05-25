//
//  Transaction.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import Foundation
import CoreTransferable
import SwiftUI
import NTPlatformKit
import DequeModule
import OrderedCollections
import UniformTypeIdentifiers

class Item: ObservableObject, Identifiable, Hashable {
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: Item, rhs: Item) -> Bool {
    lhs.id == rhs.id
  }
  
  var id = UUID()
  var name: String
  @Published var variants: [String: Int]
  @Published var transactions: OrderedSet<Transaction>
  @Published var quantity: Int = 0
  @Published var hasEmptyVariant = false
  
  init(name: String, transactions: OrderedSet<Transaction> = []) {
    self.name = name
    self.variants = [:]
    self.transactions = transactions
    self.variants[""] = 0
  }
  
  var variantCount: Int {
    hasEmptyVariant ? variants.count : (variants.count - 1)
  }
}

struct ItemTemplate: Codable, Hashable, Identifiable, Equatable {
  
  static func == (lhs: ItemTemplate, rhs: ItemTemplate) -> Bool {
    return lhs.itemName == rhs.itemName && lhs.variantName == rhs.variantName
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(itemName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines))
    hasher.combine(variantName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines))
  }
  
  var id = UUID()
  var itemID: String?
  var itemName: String
  var variantName: String
  var priceInfo: PriceInfo
}

struct INTDocument: Identifiable, Codable {
  var id: UUID = UUID()
  
  // FIXME: DO NOT remove this fixme – update document version if document model updated.
  /** The version of the document.
   
   Everytime the document model changes the developer should update the version of the document,
   the app will be able to see if the app version is lower than the document version and show alerts to users accordingly.
  */
  var version: Int = 1
  var settings: Setting = Setting()
//  var entityTemplates: [Entity]
  var itemTemplates: OrderedSet<ItemTemplate> = []
  var transactions: [Transaction] = []
  
  mutating func saveAsTemplate(_ itemTransaction: ItemTransaction) {
    // FIXME: currently, this will only be saved along with the saved transaction. If transaction is not saved, then this won't be saved
    let itemName = itemTransaction.itemName
    let variantName = itemTransaction.variant?.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? ""
    let newTemplate = ItemTemplate(itemID: itemTransaction.itemID,
                                   itemName: itemName,
                                   variantName: variantName,
                                   priceInfo: itemTransaction.priceInfo)
    
    itemTemplates.updateOrAppend(newTemplate)
  }
}

extension UTType {
  static let inTransactDocument: UTType = UTType(exportedAs: "com.intransact.document")
}

extension INTDocument: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .inTransactDocument)
  }
}
