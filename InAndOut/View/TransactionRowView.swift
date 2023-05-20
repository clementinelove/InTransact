//
//  TransactionRowView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI


struct TransactionRowView: View {
  
  @EnvironmentObject var document: InAndOutDocument
  @Binding var transaction: Transaction
  let currencyIdentifier: String
  @Environment(\.locale) private var locale
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  
  var body: some View {
    let layout = dynamicTypeSize >= .accessibility1 ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    
    VStack(alignment: .leading, spacing: 4) {
      // MARK: Date and Transaction Identifier
      Text(transaction.transactionID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? "NO ID SPECIFIED")
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(Global.transactionIDHighlightColor)
        .fontWeight(.medium)
        .lineLimit(1)
        .font(.caption)
      
      layout {
        Text(transactionDateFormatter.string(from: transaction.date))
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(1)
        Spacer()
        
        Text(transaction.total(roundingRules: document.content.settings.roundingRules).formatted(.currency(code: currencyIdentifier)))
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
          Text(type == .itemsIn ? "IN" : "OUT")
            .lineLimit(1)
        }
        
        Text("·").fontWeight(.bold)
        
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          
          Text(transaction.date.formatted(.relative(presentation: .named)).capitalized)
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
        Text(transaction.subtransactions.isEmpty ? "No Items Available" : itemDetails)
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
          TransactionRowView(transaction: .constant(.mock()), currencyIdentifier: Global.currentCurrencyCode)
          
        }
      }
      .listStyle(.plain)
      .environmentObject(InAndOutDocument.mock())
    }
  }
}
