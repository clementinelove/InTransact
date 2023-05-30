//
//  TransactionDetailView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI
import NTPlatformKit

struct TransactionDetailView: View {
  
  @EnvironmentObject private var document: InTransactDocument
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
  @State private var sharedTaxInfo: (regular: [RateTaxItem: Decimal],
                                     compound: [RateTaxItem: Decimal],
                                     fixed: [FixedAmountItem: Decimal])? = nil
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        VStack(alignment: .leading) {
          Text("Transaction", comment: "Navigation title of a transaction")
            .font(.caption.smallCaps())
            .fontWeight(.medium)
          
          HStack {
            if let transactionID = transaction.transactionID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Text(transactionID)
                .font(.title3.monospaced().bold())
                .foregroundColor(Global.transactionIDHighlightColor)
            } else {
              Text("No ID Specified")
                .font(.title3.monospaced().bold())
                .foregroundColor(.gray)
            }
            
            Spacer()
          }
          .padding(.bottom, 2)
          
          // MARK: Date
          Text(transaction.date.formatted(date: .long, time: .shortened))
            .font(.subheadline)
            .padding(.bottom)
          
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Label {
                switch transaction.transactionType {
                  case .itemsIn:
                    Text("Items In")
                  case .itemsOut:
                    Text("Items Out")
                }
              } icon: {
                Image(systemName: transaction.transactionType == .itemsIn ? "arrow.down.circle" : "arrow.up.circle")
                  .fontWeight(.medium)
              }
            }
            
            // MARK: Keeper
            if let keeper = transaction.keeperName?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Label {
                Text(verbatim: keeper)
              } icon: {
                Image(systemName: "pencil.circle")
              }
            }
          }
          .font(.callout)
          .padding(.bottom, 4)
          
          // MARK: Comments
          if !transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(transaction.comment)
              .textSelection(.enabled)
              .font(.callout)
              .foregroundStyle(.secondary)
            
          }
        }
        .listRowSeparator(.hidden, edges: .top)
        
        Divider()
        
        // MARK: Items
        VStack(spacing: 10) {
          ForEach($transaction.subtransactions) { t in
            ItemTransactionRow(itemTransaction: t, showTaxDetails: (sharedTaxInfo == nil ? true : false))
              .id(t.wrappedValue.itemName)
          }
        }
        
        Divider()
        sharedTaxInfoView
        fixedTransactionCostView
      }
      .padding()
    }
    .navigationTitle("")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .listStyle(.plain)
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
        #if os(iOS)
.toolbarRole(.navigationStack)
#endif
      }
    }
#if os(iOS)
    .toolbar {
      
      ToolbarItemGroup(placement: .bottomBar) {
        LabeledContent {
          Text(verbatim: document.formattedTransactionTotal(transaction.total(roundingRules: document.roundingRules)))
        } label: {
          Text("Total")
            .textCase(.uppercase)
        }
        .font(.body.bold())
        .foregroundStyle(.primary)
      }
      
    }
#endif
    .alert("Delete Transaction \"\(transaction.transactionID)\"?", isPresented: $showDeleteConfirmationAlert) {
      Button("Delete", role: .destructive) {
        // Handle delete
        dismiss()
        onDelete()
      }
    } message: {
      Text("You cannot undo this action.")
    }
    .task(id: transaction) {
      sharedTaxInfo = transaction.sharedTaxInfo(taxRoundingRule: document.roundingRules.taxItemRule)
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
  
  @State private var isShowingTotalDetails = false
  
  @ViewBuilder
  var sharedTaxInfoView: some View {
    
    if let (regular, compound, fixed) = sharedTaxInfo {
      
      LabeledContent {
        Text(verbatim: transaction.subtotal().formatted(.currency(code: document.currencyCode)))
          .foregroundStyle(.primary)
      } label: {
        Text("Subtotal")
          .fontWeight(.medium)
      }
      
      Section {
        ForEach(regular.sorted(using: KeyPathComparator(\.key.name, order: .forward)), id: \.key) { taxEntry in
          LabeledContent {
            Text(verbatim: "\(document.formattedTaxItem(taxEntry.value))")
              .foregroundStyle(.primary)
          } label: {
            Text("\(taxEntry.key.name)")
              .fontWeight(.medium)
            Text("Regular Tax at \(taxEntry.key.rate.formatted(.percent))")
          }
        }
        
        ForEach(compound.sorted(using: KeyPathComparator(\.key.name, order: .forward)), id: \.key) { taxEntry in
          LabeledContent {
            Text(verbatim: "\(document.formattedTaxItem(taxEntry.value))")
              .foregroundStyle(.primary)
          } label: {
            Text("\(taxEntry.key.name)")
              .fontWeight(.medium)
            Text("Compound Tax at \(taxEntry.key.rate.formatted(.percent))")
          }
        }
        ForEach(fixed.sorted(using: KeyPathComparator(\.key.name, order: .forward)), id: \.key) { taxEntry in
          LabeledContent {
            // FIXME: the number is being rounded here, doesn't really make sense to customer
            Text(verbatim: "\(taxEntry.value.formatted(.currency(code: document.currencyCode).precision(.fractionLength(taxEntry.value.decimalPlacesCount(for: document.currencyCode)))))")
              .foregroundStyle(.primary)
          } label: {
            Text("\(taxEntry.key.name)")
              .fontWeight(.medium)
            Text("Fixed Tax Per Item")
          }
        }
      }
      

//      .foregroundStyle(.primary)
      
      
    }
  }
  
  var fixedTransactionCostView: some View {
    ForEach(transaction.fixedCosts) { costItem in
      LabeledContent {
        // FIXME: the number is being rounded here, doesn't really make sense to customer
        Text(verbatim: "\(costItem.amount .formatted(.currency(code: document.currencyCode).precision(.fractionLength(costItem.amount.decimalPlacesCount(for: document.currencyCode)))) )")
          .foregroundStyle(.primary)
      } label: {
        Text("\(costItem.name)")
          .fontWeight(.medium)
        
      }
    }
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
        Text(transaction.total.formatted(.currency(code: document.currencyCode)))
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
            
            
            Text(t.total.formatted(.currency(code: document.currencyCode)))
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
      
        TransactionDetailView(transaction: .constant(.mock()), onDelete: { })
        .environmentObject(InTransactDocument.mock())
    }
    Rectangle().sheet(isPresented: .constant(true)) {
      NavigationStack {
        
          TransactionDetailView(transaction: .constant(.mock()), onDelete: { })
        
        .environmentObject(InTransactDocument.mock())
      }
    }
    .previewDisplayName("In a Sheet")
    
    
//    TransactionSnapShotView(transaction: .mock())
  }
}
