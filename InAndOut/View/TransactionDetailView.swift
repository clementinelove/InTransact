//
//  TransactionDetailView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI

struct TransactionDetailView: View {
  
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.displayScale) private var displayScale
  @Environment(\.dismiss) private var dismiss
  @Environment(\.undoManager) private var undoManager
  
  @Binding var transaction: Transaction
  var scrollToItemName: String? = nil
  let onDelete: () -> Void

  @State private var showItemTransactionDetails: Binding<ItemTransaction>? = nil
  @State private var showTransactionEditView = false
  @State private var showDeleteConfirmationAlert = false
  
  @State private var transactionImage: Image = Image(systemName: "photo")
  
  
  var body: some View {
        VStack(alignment: .leading) {
          VStack(alignment: .leading) {
            
            Text("Transaction")
              .font(.caption.smallCaps())
            
            Text(transaction.transactionID)
              .font(.title3.bold())
              .foregroundColor(.accentColor)
              .padding(.bottom, 2)
            Text(transaction.date.formatted(date: .long, time: .shortened))
              .font(.subheadline)
            
            // MARK: Location
            
            
            // MARK: Keeper
            if let keeper = transaction.keeperName?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              HStack {
                Image(systemName: "pencil.line")
                  .symbolVariant(.fill)
                Text(keeper)
                  .textSelection(.enabled)
              }
              .padding(.vertical, 6)
            }
            
            
            // MARK: Comments
            if !transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              Text(transaction.comment)
                .textSelection(.enabled)
                .font(.callout)
                .foregroundStyle(.secondary)
              
            }
          }
          .listRowSeparator(.hidden, edges: .top)
          
          VStack(spacing: 10) {
            Divider()
            HStack {
              Text("Total".uppercased())
              Spacer()
              Text(transaction.total(roundingRules: document.content.settings.roundingRules).formatted(.currency(code: document.content.settings.currencyIdentifier)))
            }
            .font(.body.bold())
            Divider()
          }
          
          VStack(spacing: 10) {
            // MARK: Items
            ForEach($transaction.subtransactions) { t in
              ItemTransactionRow(itemTransaction: t, showTaxDetails: false)
              .id(t.wrappedValue.itemName)
            }
          }
        }
    .navigationTitle("")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .listStyle(.plain)
    .onAppear { render() }
    .sheet(isPresented: $showTransactionEditView) {
      Task {
        await MainActor.run {
          showTransactionEditView = false
        }
      }
    } content: {
      NavigationStack {
        TransactionEditView(edit: transaction) { editedTransaction in
          document.replaceTransactionContent(with: editedTransaction, undoManager: undoManager)
        }
        .toolbarRole(.navigationStack)
      }
    }
    .alert("Delete Transaction \"\(transaction.transactionID)\"?", isPresented: $showDeleteConfirmationAlert) {
      Button("Delete", role: .destructive) {
        // Handle delete
        dismiss()
        onDelete()
      }
    } message: {
      Text("You cannot undo this action.")
    }

  }
  
  var shareButton: some View {
    ShareLink("Transaction \(transaction.transactionID)", item: transactionImage, preview: SharePreview(Text("Transaction \(transaction.transactionID)"), image: transactionImage))
  }
  
  var moreButton: some View {
    Menu {
      editButton
      deleteButton
    } label: {
      Image(systemName: "ellipsis.circle")
    }
  }
  
  var editButton: some View {
    Button {
      showTransactionEditView = true
    } label: {
      Label("Edit Transaction", systemImage: "pencil.circle")
    }
  }
  
  var deleteButton: some View {
    Button(role: .destructive) {
      showDeleteConfirmationAlert = true
    } label: {
      Label("Delete Transaction", systemImage: "trash.circle")
    }
  }
  
  @MainActor func render() {
//    let renderer = ImageRenderer(content: TransactionSnapShotView(transaction: transaction))
    
    // make sure and use the correct display scale for this device
//    renderer.scale = displayScale
//    
//    if let uiImage = renderer.uiImage {
//      transactionImage = Image(uiImage: uiImage)
//      
//    }
  }
}

/*
struct TransactionSnapShotView: View {
  
  let transaction: Transaction
  
  var body: some View {
    List {
      VStack(alignment: .leading) {
        Text("Transaction")
          .font(.caption.smallCaps())
        
        Text(transaction.transactionID)
          .font(.title3.bold())
          .foregroundColor(.accentColor)
          .padding(.bottom, 2)
        Text(transaction.date.formatted(date: .long, time: .shortened))
          .font(.subheadline)
        
        // MARK: Keeper
        HStack {
          Image(systemName: "person")
            .symbolVariant(.fill)
          Text("James Smith")
            .textSelection(.enabled)
        }
        .padding(.vertical, 6)
        
        // MARK: Comments
        if !transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(transaction.comment)
            .textSelection(.enabled)
            .font(.callout)
            .foregroundStyle(.secondary)
          
        }
      }
      .listRowSeparator(.hidden, edges: .top)
      
      HStack {
        Text("Total".uppercased())
        Spacer()
        Text(transaction.total.formatted(.currency(code: document.content.settings.currencyIdentifier)))
      }
      .font(.body.bold())
      
      // MARK: Items
      Grid(alignment: .topLeading, verticalSpacing: 6) {
        ForEach(transaction.subtransactions) { t in
          GridRow(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
              Text("\(t.itemName)")
                .font(.headline)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
              if let variant = t.variant {
                Text("\(variant)")
                  .foregroundColor(.secondary)
              }
            }
            
            
            Text(t.total.formatted(.currency(code: document.content.settings.currencyIdentifier)))
              .multilineTextAlignment(.trailing)
              .gridColumnAlignment(.trailing)
          }
        }
      }
    }
    .listStyle(.plain)
  }
}
 */

struct TransactionDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView(.vertical) {
        TransactionDetailView(transaction: .constant(.mock()), onDelete: { })
          .padding()
      }
        .environmentObject(InAndOutDocument.mock())
    }
//    TransactionSnapShotView(transaction: .mock())
  }
}