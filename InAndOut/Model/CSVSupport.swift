//
//  CSVSupport.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import Foundation
import DequeModule
import CoreTransferable
import NTPlatformKit

// FIXME: allow custom column name according to params instead of just column name

protocol ExportTableColumn {
  associatedtype T
  var id: UUID { get } // I am being sloppy for UI Purposes
  var columnName: String { get }
  var columnDataExtractor: (T) -> String { get }
}

struct TransactionTableColumn: ExportTableColumn {
  let id: UUID = UUID()
  var columnName: String
  var columnDataExtractor: (Transaction) -> String
}

struct ItemTransactionTableColumn: ExportTableColumn {
  let id: UUID = UUID()
  var columnName: String
  var columnDataExtractor: (ItemTransaction) -> String
}

enum INTExportColumn: Identifiable {
  
  var id: UUID {
    switch self {
      case .itemTransaction(let c): return c.id
      case .transaction(let c): return c.id
    }
  }
  
  var columnName: String {
    switch self {
      case .itemTransaction(let c): return c.columnName
      case .transaction(let c): return c.columnName
    }
  }
  
  case transaction(TransactionTableColumn)
  case itemTransaction(ItemTransactionTableColumn)
  
  static let transactionType = Self.transaction(.init(columnName: .init(localized: "Transaction Type"))
                                                      { $0.transactionType.description })
  
  static let transactionNotes = Self.transaction(.init(columnName: .init(localized: "Notes & Comments"))
                                                       { $0.comment })
  
  static let transactionID = Self.transaction(.init(columnName: .init(localized: "Transaction ID"))
                                                    { $0.transactionID })
  
  static let transactionDateAndTime = Self.transaction(.init(columnName: .init(localized: "Date & Time"))
                                                { $0.date.formatted(date: .numeric, time: .shortened) })
  
  static let transactionDate = Self.transaction(.init(columnName: .init(localized: "Transaction Date"))
                                                { $0.date.formatted(date: .numeric, time: .omitted) })
  
  static let transactionTime = Self.transaction(.init(columnName: .init(localized: "Transaction Time"))
                                                { $0.date.formatted(date: .omitted, time: .shortened) })
  
  static let itemName = Self.itemTransaction(.init(columnName: .init(localized: "Item Name"))
                                             { $0.itemName })
  
  static let variantName = Self.itemTransaction(.init(columnName: .init(localized: "Variant Name"))
                                                { $0.variant ?? ""})
  
  static func pricePerUnitBeforeTax(settings: Setting) -> INTExportColumn {
    .itemTransaction(.init(columnName: .init(localized: "Item Unit Price Before Tax"),
                           columnDataExtractor: {

      $0.priceInfo.pricePerUnitBeforeTax
        .formatted(.currency(code: settings.currencyIdentifier))
    }))
  }
  
  static func pricePerUnitAfterTax(settings: Setting) -> INTExportColumn {
    .itemTransaction(.init(columnName: .init(localized: "Item Unit Price After Tax"),
                           columnDataExtractor: {
      
      $0.priceInfo.pricePerUnitAfterTax(taxItemRounding: settings.roundingRules.taxItemRule,
                                        totalRounding: settings.roundingRules.itemSubtotalRule)
        .formatted(.currency(code: settings.currencyIdentifier))
    }))
  }
  
  static func itemTaxTotal(settings: Setting) -> INTExportColumn {
    .itemTransaction(.init(columnName: .init(localized: "Item Tax Total"),
                           columnDataExtractor: {
      $0.priceInfo.allTaxSum(roundedWith: settings.roundingRules.taxItemRule)
        .formatted(.currency(code: settings.currencyIdentifier))
    }))
  }
  
  static func itemSubtotalAfterTax(settings: Setting) -> INTExportColumn {
    .itemTransaction(.init(columnName: .init(localized: "Item Subtotal After Tax")) {
      $0
        .priceInfo
        .totalAfterTax(taxItemRounding: settings.roundingRules.taxItemRule,
                       itemSubtotalRounding: settings.roundingRules.itemSubtotalRule)
        .formatted(.currency(code: settings.currencyIdentifier))
      
    })
  }
  
  static func transactionTotalAfterTax(settings: Setting) -> INTExportColumn {
    .transaction(.init(columnName: .init(localized: "Transaction Total After Tax")) {
      
      $0.total(roundingRules: settings.roundingRules)
        .formatted(.currency(code: settings.currencyIdentifier).grouping(.never))
    })
  }
  
  static let itemQuantity = Self.itemTransaction(.init(columnName: .init(localized: "Item Quantity")) { itemTransaciton in
    itemTransaciton.priceInfo.quantity.formatted(.number.precision(.fractionLength(0)))
  })
}

import os.log

fileprivate let logger = Logger(subsystem: Global.subsystem, category: "CSVExporter")

extension INTDocument {
  
  static let documentExportPath: URL = FileManager.default.temporaryDirectory.appending(path: "exports", directoryHint: .isDirectory)
  static func exportFilePath(fileName: String) -> URL { documentExportPath.appending(path: fileName, directoryHint: .notDirectory) }
  enum Granularity {
    case transaction
    case item
  }
    
  /// Generate rows on per item basis. Returns the file path of the generated document.
  func separatedValueDocument(fileName: String, seperator: String, columns: [INTExportColumn]) throws -> URL {
    
    let recordSeparator = "\n"
    
    var svDocumentString: String = ""
    // Generate header row
    svDocumentString.append(buildRow(columns.map { $0.columnName },
                                     separator: seperator,
                                     recordSeperator: recordSeparator))
    for transaction in transactions {
      for item in transaction.subtransactions {
        var rowCellValues: [String] = []
        
        for column in columns {
          var value: String = ""
          switch column {
            case .itemTransaction(let exportColumn):
              value = exportColumn.columnDataExtractor(item)
            case .transaction(let exportColumn):
              value = exportColumn.columnDataExtractor(transaction)
          }
          
          // Add surrounded quotes for each field (also replace double quotes with double double quotes i.e. "")
          rowCellValues.append(value.replacingOccurrences(of: "\"", with: "\"\"").surrounded(by: "\""))
        }
        
        svDocumentString.append(buildRow(rowCellValues, separator: seperator, recordSeperator: recordSeparator))
      }
    }
    try clearExportDirectory()
    do {
      logger.debug("Start Creating Export Directory")
      try FileManager.default.createDirectory(at: Self.documentExportPath, withIntermediateDirectories: false)
      logger.debug("Export Directory Created")
    } catch {
      logger.debug("Fail to Create Export Directory: \(error.localizedDescription)")
    }
    
    let exportFilePath = Self.exportFilePath(fileName: fileName)
    // TODO: create file if file doesn't exist?
    
    try svDocumentString.write(to: exportFilePath, atomically: true, encoding: .utf16)
    logger.debug("New Export Write To \(exportFilePath.debugDescription)")
    return exportFilePath
  }
  
  func clearExportDirectory() throws {
    logger.debug("Start Cleaning Export Directory")
    try? FileManager.default.removeItem(at: Self.documentExportPath)
    logger.debug("Finish Cleaning Export Directory")
  }
}

struct CSVDocument: Transferable {
  
  let data: Data
  
  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .commaSeparatedText) { $0.data }
  }
}
