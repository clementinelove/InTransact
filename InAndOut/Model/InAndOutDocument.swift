//
//  InTransactDocument.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import UniformTypeIdentifiers
import DequeModule
import OrderedCollections
import OSLog

fileprivate let logger = Logger(subsystem: Global.subsystem, category: "InTransactDocument")

final class InTransactDocument: ReferenceFileDocument {
  
  @Published var content: INTDocument
  typealias Snapshot = INTDocument
  
#if os(iOS) // Edit mode doesn't exist in macOS.
  @Environment(\.editMode) var editMode
#endif // os(iOS)
  
  static var readableContentTypes: [UTType] { [.inTransactDocument] }
  
  func snapshot(contentType: UTType) throws -> INTDocument {
    content // Make a copy
  }
  
  init(mock: Bool = true) {
    if mock {
      self.content = .mock()
    } else {
      self.content = INTDocument(settings: Setting())
    }
  }
  
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    // TODO: decode
    self.content = try JSONDecoder().decode(INTDocument.self, from: data)
//    self.content = INTDocument.mock() // for testing
  }
  
  func fileWrapper(snapshot: INTDocument, configuration: WriteConfiguration) throws -> FileWrapper {
    logger.debug("Save called")
    let data = try JSONEncoder().encode(snapshot)
    let fileWrapper = FileWrapper(regularFileWithContents: data)
    return fileWrapper
  }
  
}

extension InTransactDocument {
  static func mock() -> InTransactDocument {
    InTransactDocument(mock: true)
  }
}

// MARK: - Shortcuts
extension InTransactDocument {
  
  var currencyCode: String {
    content.settings.currencyIdentifier
  }
  
  var roundingRules: RoundingRuleSet {
    content.settings.roundingRules
  }
  
  func formattedTaxItem(_ price: Price) -> String {
    formattedPrice(price, scale: roundingRules.taxItemRule.scale)
  }
  
  func formattedItemSubtotal(_ price: Price) -> String {
    formattedPrice(price, scale: roundingRules.itemSubtotalRule.scale)
  }
  
  func formattedTransactionTotal(_ price: Price) -> String {
    formattedPrice(price, scale: roundingRules.transactionTotalRule.scale)
  }
  
  private func formattedPrice(_ price: Price, scale: Int) -> String {
    price.formatted(.currency(code: currencyCode)
      .precision(.fractionLength(scale)))
  }
}


// MARK: - Undo Actions
extension InTransactDocument {
  
  func saveContact(_ contact: Contact, undoManager: UndoManager? = nil) {
    // Copy old templates.
    let oldTemplates = content.contactTemplates
    
    // Make new template from the given item transaction.
    let newTemplate = ContactTemplate(contact: contact)
    content.contactTemplates.updateOrAppend(newTemplate)
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.updateContactTemplates(newTemplates: oldTemplates, undoManager: undoManager)
    }
  }
  
  func updateContactTemplates(newTemplates: OrderedSet<ContactTemplate>, undoManager: UndoManager? = nil) {
    let oldTemplates = content.contactTemplates // copy old templates
    content.contactTemplates = newTemplates
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.updateContactTemplates(newTemplates: oldTemplates, undoManager: undoManager)
    }
  }
  
  func saveAsItemTemplate(_ itemTransaction: ItemTransaction, undoManager: UndoManager? = nil) {
    // Copy old templates.
    let oldTemplates = content.itemTemplates
    
    // Make new template from the given item transaction.
    let itemName = itemTransaction.itemName
    let variantName = itemTransaction.variant?.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? ""
    let newTemplate = ItemTemplate(itemID: itemTransaction.itemID,
                                   itemName: itemName,
                                   variantName: variantName,
                                   priceInfo: itemTransaction.priceInfo)
    content.itemTemplates.updateOrAppend(newTemplate)
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.updateItemTemplates(newTemplates: oldTemplates, undoManager: undoManager)
    }
  }
  
  func updateItemTemplates(newTemplates: OrderedSet<ItemTemplate>, undoManager: UndoManager? = nil) {
    let oldTemplates = content.itemTemplates // copy old templates
    content.itemTemplates = newTemplates
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.updateItemTemplates(newTemplates: oldTemplates, undoManager: undoManager)
    }
  }
  
  func updateSettings(_ newSettings: Setting, undoManager: UndoManager? = nil) {
    let oldSettings = content.settings
    content.settings = newSettings
    logger.debug("Update from \n\(oldSettings.debugDescription)\n to \n\(newSettings.debugDescription)")
    
    undoManager?.registerUndo(withTarget: self) { doc in
      // Because it calls itself, this is redoable, as well.
      doc.updateSettings(oldSettings, undoManager: undoManager)
    }
    
    undoManager?.setActionName(String(localized: "Update Settings",
                                      comment: "The undoable action name of updating settings"))
  }
  
  func addNewTransaction(_ transaction: Transaction, undoManager: UndoManager? = nil) {
    content.transactions.insert(transaction, at: 0)
    undoManager?.registerUndo(withTarget: self, handler: { doc in
      withAnimation {
        doc.deleteTransaction(index: 0, undoManager: undoManager)
      }
    })
//    undoManager?.setActionName("Add New Transaction")
  }
  
  /// Deletes the transaction at an index, and registers an undo action.
  func deleteTransaction(index: Int, undoManager: UndoManager? = nil) {
    let oldItems = content.transactions
    withAnimation {
      _ = content.transactions.remove(at: index)
    }
    
    undoManager?.registerUndo(withTarget: self) { doc in
      // Use the replaceItems symmetric undoable-redoable function.
      doc.replaceTransactions(with: oldItems, undoManager: undoManager)
    }
  }
  
  /// Deletes the transactions with specified IDs.
  func deleteTransactions(withIDs ids: [UUID], undoManager: UndoManager? = nil) {
    var indexSet: IndexSet = IndexSet()
    
    let enumerated = content.transactions.enumerated()
    for (index, item) in enumerated where ids.contains(item.id) {
      indexSet.insert(index)
    }
    
    deleteTransactions(offsets: indexSet, undoManager: undoManager)
  }
  
  /// Replaces the existing transactions with a new set of transactions.
  func replaceTransactions(with newTransactions: [Transaction], undoManager: UndoManager? = nil, animation: Animation? = .default) {
    let oldTransactions = content.transactions
    
    withAnimation(animation) {
      content.transactions = newTransactions
    }
    
    undoManager?.registerUndo(withTarget: self) { doc in
      // Because you recurse here, redo support is automatic.
      doc.replaceTransactions(with: oldTransactions, undoManager: undoManager, animation: animation)
    }
  }
  
  /// Deletes the transactions at a specified set of offsets, and registers an undo action.
  func deleteTransactions(offsets: IndexSet, undoManager: UndoManager? = nil) {
    let oldTransactions = content.transactions
    withAnimation {
      content.transactions.remove(atOffsets: offsets)
    }
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.replaceTransactions(with: oldTransactions, undoManager: undoManager)
    }
  }
  
  /// Deletes the transactions at a specified set of offsets, and registers an undo action.
  // TODO: add old transaction in args in order to utilize reference type to improve performance
  func replaceTransactionContent(with transaction: Transaction,
                                 undoManager: UndoManager? = nil) {
    let index = content.transactions.firstIndex { $0.id == transaction.id }!
    let old = content.transactions[index]
    content.transactions[index] = transaction
    
    logger.debug("Old transaction replaced")
    
    undoManager?.registerUndo(withTarget: self) { doc in
      doc.replaceTransactionContent(with: old, undoManager: undoManager)
    }
  }
  
  /// Replaces contents of an item transaction.
  func replaceItemContent(of transaction: Transaction,
                          with item: ItemTransaction,
                          undoManager: UndoManager? = nil) {
    
    guard let transactionIndex = content.transactions.firstIndex(of: transaction) else {
       return
    }
    let items = content.transactions[transactionIndex].subtransactions
    let itemIndex = items.firstIndex { $0.id == item.id }!
    let old = items[itemIndex]
    logger.debug("Old item replaced")
    
    content.transactions[transactionIndex].subtransactions[itemIndex] = item
    
    undoManager?.registerUndo(withTarget: self, handler: { doc in
      doc.replaceItemContent(of: transaction, with: old, undoManager: undoManager)
    })
  }
}
