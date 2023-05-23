//
//  DocumentExportView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-22.
//

import SwiftUI

struct DocumentExporter {
  let document: InTransactDocument
  var exportColumns: [ExportColumnRow]
  
  init(document: InTransactDocument) {
    self.document = document
    
    let defaultExportColumns: [INTExportColumn] = [
      .transactionType, .transactionDate, .transactionID, .itemName, .variantName, .transactionNotes, .totalAfterTax(settings: document.content.settings)
    ]
    
    self.exportColumns = defaultExportColumns.map { ExportColumnRow(exportColumn: $0)
    }
    
  }
}

struct ExportColumnRow: Identifiable {
  var id: UUID = UUID()
  var isEnabled: Bool = true
  var exportColumn: INTExportColumn
}


struct DocumentExportView: View {

  enum ExportRange {
    case all
    case ranged
  }
  
  @State private var exporter: DocumentExporter = DocumentExporter(document: InTransactDocument(mock: false))
  @State private var exportRange: ExportRange = .all
  @State private var exportStartDate: Date = Date.now
  @State private var exportEndDate: Date = Date.now
  
  init(document: InTransactDocument) {
    self._exporter = State(initialValue: DocumentExporter(document: document))
    self.exportRange
  }
  
    var body: some View {
      List {
        
        Section("Columns") {
          ForEach($exporter.exportColumns) { $column in
            HStack {
              Text($column.wrappedValue.exportColumn.columnName)
              Toggle(isOn: $column.isEnabled) {
                
              }
            }
          }
          .onMove { offsets, destination in
            exporter.exportColumns.move(fromOffsets: offsets, toOffset: destination)
          }
        }
        
      }
      #if os(iOS)
      .environment(\.editMode, .constant(.active))
      #endif
      .navigationTitle("Export")
    }
}

struct DocumentExportView_Previews: PreviewProvider {
    static var previews: some View {
      DocumentExportView(document: InTransactDocument.mock())
    }
}
