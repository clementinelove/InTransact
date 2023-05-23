//
//  CSVSupport.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import Foundation
import DequeModule

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
  
  static let transactionType = Self.transaction(.init(columnName: "Transaction Type")
                                                      { $0.transactionType.description })
  
  static let transactionNotes = Self.transaction(.init(columnName: "Notes")
                                                       { $0.comment })
  
  static let transactionID = Self.transaction(.init(columnName: .init(localized: "Transaction ID"))
                                                    { $0.transactionID })
  
  static let transactionDate = Self.transaction(.init(columnName: "Date")
                                                { $0.date.formatted(date: .numeric, time: .shortened) })
  
  static let itemName = Self.itemTransaction(.init(columnName: "Item Name")
                                             { $0.itemName })
  
  static let variantName = Self.itemTransaction(.init(columnName: "Variant Name")
                                                { $0.variant ?? ""})
  
  static func totalAfterTax(settings: Setting) -> INTExportColumn {
    .itemTransaction(.init(columnName: "Price") { itemTransaciton in
      itemTransaciton
        .priceInfo
        .totalAfterTax(taxItemRounding: settings.roundingRules.taxItemRule,
                       totalRounding: settings.roundingRules.itemTotalRule)
        .formatted(.currency(code: settings.currencyIdentifier))
    })
  }
  
  static let itemQuantity = Self.itemTransaction(.init(columnName: "Item Quantity") { itemTransaciton in
    itemTransaciton.priceInfo.quantity.description
  })
  
//  static let unitPriceBeforeTax = Self.itemTransaction(.init(columnName: "Unit Price (Before Tax)")
//                                                       { $0.pricePerUnitBeforeTax.formatted(.number) })
//  
//  static let unitPriceAfterTax = Self.itemTransaction(.init(columnName: "Unit Price (After Tax)")
//                                                      { itemTransaciton in //    itemTransaciton.pricePerUnitAfterTax.formatted(.currency(code: ))
//  })

}



//extension ExportTableColumn where T == ItemTransaction {
//  static let itemName = ExportTableColumn<ItemTransaction>(columnName: "Item Name") { item in
//    item.itemName
//  }
//
//  static let variantName = ExportTableColumn(columnName: "Item Name") { item in
//    item.variant ?? INTDocument.emptyValuePlaceholder
//  }
//}

extension INTDocument {
  
  enum Granularity {
    case transaction
    case item
  }
  
  func csv(columns: [INTExportColumn]) throws -> Data? {
    separatedValueDocument(seperator: ",", columns: columns)
  }
  
  func tsv(columns: [INTExportColumn]) throws -> Data? {
    separatedValueDocument(seperator: "\t", columns: columns)
  }
  
  /// Generate rows on per item basis
  func separatedValueDocument(seperator: String, columns: [INTExportColumn]) -> Data? {
    
    var svDocumentString: String = ""
    
    for transaction in transactions {
      for item in transaction.subtransactions {
        var rowCellValues: [String] = []
        
        for column in columns {
          let value: String?
          switch column {
            case .itemTransaction(let exportColumn):
              value = exportColumn.columnDataExtractor(item)
            case .transaction(let exportColumn):
              value = exportColumn.columnDataExtractor(transaction)
          }
          if let value {
            rowCellValues.append(value)
          }
        }
        
        svDocumentString.append(buildRow(rowCellValues, separator: seperator, recordSeperator: "\n"))
      }
    }
    
    return svDocumentString.data(using: .utf8, allowLossyConversion: false)
  }
  
  
}
