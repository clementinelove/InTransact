//
//  ItemTransactionDetailView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-08.
//

import SwiftUI

struct ItemTransactionDetailView: View {
  
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.dismiss) private var dismiss
  @Environment(\.undoManager) private var undoManager
  
  @Binding var transaction: Transaction
  @Binding var itemTransaction: ItemTransaction
  @State private var showEditView: Bool = false
  
  var body: some View {
      List {
        Section {
          VStack(alignment: .leading, spacing: 10) {
            
            // MARK: Item Name & Model
            VStack(alignment: .leading) {
              if let itemID = itemTransaction.itemID,
                 !itemID.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(itemID)
                  .font(.subheadline)
              }
              
              Text(itemTransaction.itemName)
                .font(.title.bold())
              
              if let variant = itemTransaction.variant {
                Text(variant)
                  .font(.title3)
              }
            }
          }
          .listRowSeparator(.hidden)
        }
        
        Section {
          LabeledContent("Quantity") {
            Text("\(itemTransaction.priceInfo.quantity)")
              .textSelection(.enabled)
          }
          .foregroundStyle(.primary)
          
          LabeledContent("Price Per Unit (Before Tax)") {
            Text(itemTransaction.priceInfo.pricePerUnitBeforeTax.formatted(.currency(code: document.content.settings.currencyIdentifier)))
              .textSelection(.enabled)
          }
          .foregroundStyle(.primary)
          
          LabeledContent("Total Before Tax") {
            VStack(alignment: .trailing, spacing: 4) {
              Text(itemTransaction.priceInfo.totalBeforeTax.formatted(.currency(code: document.content.settings.currencyIdentifier)))
                .font(.body)
            }
          }
          .foregroundStyle(.primary)
            
          regularTaxItems
          compoundTaxItems
          fixedTaxItems
          
          LabeledContent("Total After Tax") {
            VStack(alignment: .trailing, spacing: 4) {
              Text(itemTransaction
                .priceInfo
                .totalAfterTax(taxItemRounding: document.roundingRules.taxItemRule,
                               totalRounding: document.roundingRules.transactionTotalRule)
                  .formatted(.currency(code: document.content.settings.currencyIdentifier)))
                .font(.body)
            }
          }
          .foregroundStyle(.primary)
        }
      }
      .listStyle(.plain)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        HStack {
          Button {
            showEditView = true
          } label: {
            Text("Edit")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 6)
          }
          .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
      }
      .sheet(isPresented: $showEditView) {
        Task {
          await MainActor.run {
            showEditView = false
          }
        }
      } content: {
        NavigationStack {
          ItemTransactionEditView(edit: itemTransaction) { resultItemTransaction in
            document.replaceItemContent(of: transaction, with: resultItemTransaction, undoManager: undoManager)
            print("Replaced: \(resultItemTransaction)")
          }
            
            .toolbarRole(.navigationStack)
        }
      }

    
  }
  
  var regularTaxItems: some View {
    Group {
      ForEach(itemTransaction.priceInfo.regularTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Regular Tax")
            .font(.caption2)
          LabeledContent("\(taxItem.name) (\(taxItem.rate.formatted(.percent)))", value: taxItem.taxCost(of: itemTransaction.priceInfo.totalBeforeTax) , format: .currency(code: Global.currentCurrencyCode))
            .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var compoundTaxItems: some View {
    Group {
      
      ForEach(itemTransaction.priceInfo.compoundTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Compound Tax")
            .font(.caption2)
          LabeledContent("\(taxItem.name) (\(taxItem.rate.formatted(.percent)))", value: taxItem.taxCost(of: itemTransaction.priceInfo.totalAfterRegularTax(roundedWith: document.content.settings.roundingRules.taxItemRule)), format: .currency(code: Global.currentCurrencyCode))
            .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var fixedTaxItems: some View {
    Group {
      
      ForEach(itemTransaction.priceInfo.fixedAmountTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Fixed Tax")
            .font(.caption2)
          LabeledContent("\(taxItem.name)", value: taxItem.amount, format: .currency(code: Global.currentCurrencyCode))
            .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var doneButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(.gray, .gray.opacity(0.2))
        .imageScale(.large)
    }
    .buttonStyle(.plain)
  }
}

struct ItemTransactionDetailView_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle().sheet(isPresented: .constant(true)) {
      NavigationStack {
        ItemTransactionDetailView(transaction: .constant(.mock()), itemTransaction: .constant(.mock()))
          .environmentObject(InAndOutDocument.mock())
      }
      .presentationDetents([ .large])
    }
     
    
  }
}
