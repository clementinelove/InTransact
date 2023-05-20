//
//  InAndOutDocument.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import UniformTypeIdentifiers
import DequeModule
import OrderedCollections
import OSLog

fileprivate let logger = Logger(subsystem: Global.appName, category: "InAndOutDocument")

final class InAndOutDocument: ReferenceFileDocument {
  
  @Published var content: INODocument
  typealias Snapshot = INODocument
  
#if os(iOS) // Edit mode doesn't exist in macOS.
  @Environment(\.editMode) var editMode
#endif // os(iOS)
  
  
  static var readableContentTypes: [UTType] { [.inAndOutDocument] }
  
  func snapshot(contentType: UTType) throws -> INODocument {
    content // Make a copy
  }
  
  init(mock: Bool = false) {
    if mock {
      self.content = .mock()
    } else {
      self.content = INODocument(settings: Setting())
    }
  }
  
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    // TODO: decode
    self.content = try JSONDecoder().decode(INODocument.self, from: data)
  }
  
  func fileWrapper(snapshot: INODocument, configuration: WriteConfiguration) throws -> FileWrapper {
    logger.debug("Save called")
    let data = try JSONEncoder().encode(snapshot)
    let fileWrapper = FileWrapper(regularFileWithContents: data)
    return fileWrapper
  }
  
}

extension InAndOutDocument {
  // MARK: Shortcuts
  var currencyCode: String {
    content.settings.currencyIdentifier
  }
  
  var roundingRules: RoundingRuleSet {
    content.settings.roundingRules
  }
  
}

extension InAndOutDocument {
  
  // TODO: localize action names
  func updateCurrency(_ currencyIdentifier: String, undoManager: UndoManager? = nil) {
    let oldIdentifier = content.settings.currencyIdentifier
    content.settings.currencyIdentifier = currencyIdentifier
    logger.debug("Update from \(oldIdentifier) to \(currencyIdentifier)")
    
    undoManager?.registerUndo(withTarget: self) { doc in
      // Because it calls itself, this is redoable, as well.
      doc.updateCurrency(oldIdentifier, undoManager: undoManager)
    }
    undoManager?.setActionName("Update Currency")
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