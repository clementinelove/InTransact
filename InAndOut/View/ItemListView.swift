//
//  ItemListView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-11.
//

import SwiftUI
import DequeModule

struct ItemListView: View {
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.dismiss) private var dismiss
  @Binding var nameFilter: String
  @Binding var variantNameFilter: String
  
  @State private var items: [Item] = []
  @State private var isLoading = false

  var body: some View {
    ZStack {
      List {
        ForEach(items) { item in
          Button {
            // filter transactions in the transactions list
            addFilter(item)
          } label: {
            LabeledContent {
              Text("\(item.quantity)")
                .lineLimit(1)
            } label: {
              
              VStack(alignment: .leading) {
                Text("\(item.name)")
                  .font(.headline)
                  .lineLimit(1)
                // Grammar agreement
                Text("\(item.variantCount) Variant(s)", comment: "Related Item Templates")
                  .font(.subheadline)
                Text("\(item.transactions.count) Transaction(s)")
                  .foregroundStyle(.secondary)
                  .font(.subheadline)
              }
            }
          }
        }
      }
      .listStyle(.plain)
      
      EmptyListPlaceholder("No Items")
        .opacity(items.isEmpty ? 1 : 0)
      
      ProgressView()
        .opacity(isLoading ? 1 : 0)
    }
    .task(id: document.content.transactions, priority: .userInitiated) {
      await MainActor.run {
        isLoading = true
      }
      let items = findItems(from: document.content.transactions)
      await MainActor.run {
        self.items = items
        isLoading = false
      }
    }
    .navigationTitle("Items Count")
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
    // View End
  }
  
  func addFilter(_ item:Item) {
    nameFilter = item.name
    dismiss()
  }
  
  func findItems(from transactions: [Transaction]) -> [Item] {
    var itemNameToItem: [String: Item] = [:]
    for transaction in transactions {
      let transactionType = transaction.transactionType
      for itemTransaction in transaction.subtransactions {
        let itemName = itemTransaction.itemName
        let variantName = itemTransaction.variant
        let quantityChange = (transactionType == .itemsIn) ? Int(itemTransaction.priceInfo.quantity) : ((transactionType == .itemsOut) ? -Int(itemTransaction.priceInfo.quantity) : 0)
        let item = itemNameToItem[itemName] ?? Item(name: itemName)
          
        if let variantName,
           !variantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  {
          if let variantCount = item.variants[variantName] {
            item.variants[variantName] = variantCount + quantityChange
          } else {
            item.variants[variantName] = quantityChange
          }
        } else {
          item.hasEmptyVariant = true
          item.variants[""] = item.variants[""]! + quantityChange
        }
        item.transactions.append(transaction)
        item.quantity += quantityChange
        //
        itemNameToItem[itemName] = item
        
      }
    }
    return itemNameToItem.values.sorted { $0.name < $1.name }
  }
  
}

struct ItemListView_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle()
      .sheet(isPresented: .constant(true)) {
      NavigationStack {
        ItemListView(nameFilter: .constant(""), variantNameFilter: .constant(""))
          .environmentObject(InAndOutDocument.mock())
      }
    }
    
  }
}
