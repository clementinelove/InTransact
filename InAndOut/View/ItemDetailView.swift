//
//  ItemDetailView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-11.
//

import SwiftUI
import DequeModule
import OrderedCollections

struct ItemDetailView: View {
  @EnvironmentObject private var document: InAndOutDocument
  @ObservedObject var item: Item
  
  var body: some View {
    List {
      // MARK: Item Info
      VStack(alignment: .leading)
      {
        Text(item.name)
          .font(.largeTitle.bold())
          .multilineTextAlignment(.leading)
        
        Text("Quantity: \(item.quantity)")
  
        // TODO: build a variant filter
//        ScrollView(.horizontal, showsIndicators: false) {
//          LazyHStack {
//            ForEach(item.variants.keys.sorted(), id: \.self) { variantName in
//              Button(variantName) {
//                // ...
//              }
//              .buttonStyle(.bordered)
//
//            }
//          }
//        }
      }
      .listRowSeparator(.hidden)
      // MARK: Transactions
      Section("Transactions") {
        ForEach(item.transactions) { transaction in
          NavigationLink {
            TransactionDetailView(transaction: transaction, scrollToItemName: item.name) {
              // .. on delete
              guard let index = document.content.transactions.firstIndex(where: { $0 == transaction }) else { return }
              document.deleteTransaction(index: index)
            }
            
            
          } label: {
            TransactionRowView(transaction: transaction, currencyIdentifier: document.content.settings.currencyIdentifier)
          }
        }
      }
    }
    .listStyle(.plain)
    .task(id: document.content.transactions, priority: .userInitiated) {
      var variants: [String: Int] = [:]
      // empty key for not specified variant type
      variants[""] = 0
      var totalCount: Int = 0
      var relatedTransactions = OrderedSet<Transaction>()
      
      for transaction in document.content.transactions {
        let transactionType = transaction.transactionType
        for subtransaction in transaction.subtransactions {
          if subtransaction.itemName == item.name {
            let quantityChange = transactionType == .itemsIn ? Int(subtransaction.quantity) : (transactionType == .itemsOut ? -Int(subtransaction.quantity) : 0)
            
            relatedTransactions.append(transaction)
            
            if let variant = subtransaction.variant {
              if let variantCount = variants[variant] {
                variants[variant] = variantCount + quantityChange
              } else {
                variants[variant] = quantityChange
              }
            } else {
              variants[""] = variants[""]! + quantityChange
            }
            
            totalCount += quantityChange
          }
        }
      }
      await MainActor.run {
        item.variants = variants
        item.transactions = relatedTransactions
        item.quantity = totalCount
      }
    }
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    // View End
  }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        ItemDetailView(item: Item(name: "4K Ultra HD Smart TV", transactions: [
          .mock(), .mock(), .mock()
        ]))
        .environmentObject(InAndOutDocument.mock())
      }
    }
}
