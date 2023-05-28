//
//  TransactionRowView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI


struct TransactionRowView: View {
  
  private static let localizationTable = "TransactionRow"
  
  @EnvironmentObject var document: InTransactDocument
  var transaction: Transaction
  let currencyIdentifier: String
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  
  var body: some View {
    let layout = dynamicTypeSize >= .accessibility1 ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    
    VStack(alignment: .leading, spacing: 4) {
      // MARK: Date and Transaction Identifier
      Text(transaction.transactionID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? String(localized: "No ID Specified", comment: "Transaction ID placeholder when its value is not available"))
        .textCase(.uppercase)
        .font(.system(.caption, design: .monospaced))
      #if os(iOS)
        .foregroundColor(Global.transactionIDHighlightColor)
      #elseif os(macOS)
        .foregroundColor(.primary)
      #endif
        .fontWeight(.medium)
        .lineLimit(1)
        .font(.caption)
      
      layout {
        Text(transactionDateFormatter.string(from: transaction.date))
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(1)
        Spacer()
        
        Text(document.formattedTransactionTotal(transaction.total(roundingRules: document.roundingRules)))
          .lineLimit(1)
          .layoutPriority(1)
          .font(.subheadline)
          .baselineOffset(1)
      }
      
      .padding(.bottom, 14)
      
      layout {
        let type = transaction.transactionType
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Image(systemName: type == .itemsIn ? "arrow.down.circle": "arrow.up.circle")
          if type == .itemsIn {
            Text("In", comment: "Transaction type 'items in' shorthand")
          } else {
            Text("Out", comment: "Transaction type 'items out' shorthand")
          }
        }
        .lineLimit(1)
        
        Text("·").fontWeight(.bold)
        
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          
          Text(transaction.date.formatted(.relative(presentation: .named)).localizedCapitalized)
            .lineLimit(1)
        }
        
        if let keeper = transaction.keeperName?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
          Text("·").fontWeight(.bold)
          
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            
            Text(keeper)
              .lineLimit(1)
          }
        }
      }
      .font(.callout)
      .fontWeight(.medium)
      .fontDesign(.rounded)
      
      
      // MARK: Item Count and Total$
      HStack(alignment: .firstTextBaseline) {
        
        // items count
        //          let items = transaction.items
        //          Text("(^[\(items.count) \(String(localized: "item"))](inflect: true))")
        //            .lineLimit(1)
        
        // MARK: Item Details
        Text(transaction.subtransactions.isEmpty ? String(localized: "No Items", comment: "Transaction item details placeholder when there is no item presented in the transaction") : itemDetails)
          .lineLimit(1)
          .baselineOffset(1)
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
  }
  
  var itemDetails: String {
    var itemNameToQuantity: [String: ItemQuantity] = [:]
    for transaction in transaction.subtransactions {
      let itemName = transaction.itemName
      
      if let quantity = itemNameToQuantity[itemName] {
        itemNameToQuantity[itemName] = quantity + transaction.priceInfo.quantity
      } else {
        itemNameToQuantity[itemName] = transaction.priceInfo.quantity
      }
    }
    return itemNameToQuantity.sorted { $0.key < $1.key }.map { (name, quantity) in
      "\(quantity)\(Global.timesSymbol) \(name)"
    }.joined(separator: ", ")
  }
  
  
}

struct TransactionRowView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List {
        ForEach(0..<100) { _  in
          TransactionRowView(transaction: .mock(), currencyIdentifier: Global.systemCurrentCurrencyCode)
          
        }
      }
      .listStyle(.plain)
      .environmentObject(InTransactDocument.mock())
    }
  }
}


