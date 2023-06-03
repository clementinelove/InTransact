//
//  DocumentExportView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-22.
//

import SwiftUI
import Combine
import NTPlatformKit
import os.log

fileprivate let logger = Logger(subsystem: Global.subsystem, category: "DocumentExporter")

class DocumentExporter: ObservableObject {
  let document: InTransactDocument
  @Published var exportColumnRows: [ExportColumnRow]
  @Published var exportColumns: [INTExportColumn] = []
  @Published var generatedDocumentPath: URL? = nil
  @Published var isGeneratingDocument: Bool = false
  private var csvGenerationTask: Task<Void, Error>? = nil
  private var cancellables: Set<AnyCancellable> = Set()
  private var documentTitle: String
  
  init(documentTitle: String?, document: InTransactDocument) {
    self.documentTitle = documentTitle ?? String(localized: "Untitled", comment: "File name without extension for exported file when the document doesn't have a title")
    
    
    self.document = document
    
    let defaultExportColumns: [INTExportColumn] = [
      .transactionType, .transactionDate, .transactionTime, .transactionID, .itemName, .variantName, .itemQuantity, 
      .pricePerUnitBeforeTax(settings: document.content.settings),
      .itemTaxTotal(settings: document.content.settings),
      .itemSubtotalAfterTax(settings: document.content.settings),
      .transactionTotalAfterTax(settings: document.content.settings),
      .transactionNotes
    ]
    
    self.exportColumnRows = defaultExportColumns.map { ExportColumnRow(exportColumn: $0)
    }
    
    $exportColumnRows
      .handleEvents(receiveRequest:  { [weak self] _ in
        self?.generatedDocumentPath = nil
      })
      .compactMap {
        $0
          .filter { $0.isEnabled }
          .map { $0.exportColumn }
      }
      .receive(on: RunLoop.main)
      .assign(to: \.exportColumns, on: self)
      .store(in: &cancellables)
  }
  
  @MainActor
  func generateDocument() async {
    csvGenerationTask?.cancel()
    csvGenerationTask = Task(priority: .userInitiated) {
      await MainActor.run {
        isGeneratingDocument = true
      }
      logger.debug("Start Generating Document")
      generatedDocumentPath = try document.content.separatedValueDocument(fileName: "\(documentTitle).csv", seperator: ",", columns: exportColumns)
      logger.debug("Finish Generating Document")
      if !Task.isCancelled {
        await MainActor.run {
          isGeneratingDocument = false
        }
      }
    }
  }
}

struct ExportColumnRow: Identifiable {
  var id: UUID = UUID()
  var isEnabled: Bool = true
  var exportColumn: INTExportColumn
}


struct DocumentExportView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var exporter: DocumentExporter
  @State private var exportStartDate: Date = Date.now
  @State private var exportEndDate: Date = Date.now
  
  init(title: String?, document: InTransactDocument) {
    self._exporter = StateObject(wrappedValue: DocumentExporter(documentTitle: title, document: document))
    
  }
  
  var body: some View {
      List {
        
        Section("Columns") {
          ForEach($exporter.exportColumnRows) { $column in
            Toggle(isOn: $column.isEnabled) {
              Text($column.wrappedValue.exportColumn.columnName)
            }
          }
          .onMove { offsets, destination in
            exporter.exportColumnRows.move(fromOffsets: offsets, toOffset: destination)
          }
        }
        
      }
      .onReceive(exporter.$exportColumns) { columns in
        Task {
          await exporter.generateDocument()
          NSTemporaryDirectory()
        }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        VStack {
          if let filePath = exporter.generatedDocumentPath {
          
          ShareLink(item: filePath) {
              Text("Share")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(exporter.isGeneratingDocument)
            .labelStyle(.titleOnly)
          } else {
            ProgressView()
          }
        }
        .background(.thinMaterial)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Done")
          }

        }
      }
#if os(iOS)
      .environment(\.editMode, .constant(.active))
      .navigationBarTitleDisplayMode(.inline)
#endif
      .navigationTitle("Export To CSV")
      .onDisappear {
        Task(priority: .userInitiated) {
          try exporter.document.content.clearExportDirectory()
        }
      }
    }
}



struct DocumentExportView_Previews: PreviewProvider {
    static var previews: some View {
      Rectangle()
        .sheet(isPresented: .constant(true)) {
          NavigationStack {
            DocumentExportView(title: "Test Demo", document: InTransactDocument.mock())
          }
        }
      
        
    }
}
