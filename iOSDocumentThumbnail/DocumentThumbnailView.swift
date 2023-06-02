//
//  DocumentThumbnailView.swift
//  iOSDocumentThumbnail
//
//  Created by Yuhao Zhang on 2023-06-02.
//

import SwiftUI
import NTPlatformKit

/// Deselect `InTransact` Targest when you finish testing the view.
struct DocumentThumbnailView: View {
  
  static let aspectRatio: Double = 1.4
  
    let document: INTDocument
    let aspectRatio: Double
  
  var width: Double {
    380
  }
  var height: Double {
    width * aspectRatio
  }
  
    var body: some View {
      Group {
        if document.transactions.count > 0 {
          LazyVStack(alignment: .leading) {
            ForEach(document.transactions) { transaction in
              VStack(alignment: .leading, spacing: 8) {
                // MARK: Primary Info: ID, Date, Total
                VStack(alignment: .leading) {
                  Text(verbatim: transaction.transactionID)
                    .fontDesign(.monospaced)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(.black)
                  
                  Text(verbatim: transaction.date.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                }
                
                // MARK: Secondary Info: Type, Names
                HStack(alignment: .firstTextBaseline) {
                  Label {
                    Text(verbatim: formattedTransactionTotal(transaction.total(roundingRules: document.settings.roundingRules), roundingRules: document.settings.roundingRules) )
                  } icon: {
                    switch transaction.transactionType {
                      case .itemsIn:
                        Image(systemName: "arrow.down.circle")
                      case .itemsOut:
                        Image(systemName: "arrow.up.circle")
                    }
                    
                  }
                  
                  if let counterparty = transaction.counterpartyContact,
                    let counterpartyName = counterparty.mainName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
                    Label {
                      Text(verbatim: counterpartyName)
                    } icon: {
                      if counterparty.isCompany {
                        Image(systemName: "building.2.crop.circle")
                      } else {
                        Image(systemName: "person.crop.circle")
                      }
                    }
                  }
                }
                .font(.system(size: 12, weight: .light))

                
                
              }
              Divider()
            }
          }
          
          .padding(20)
          .frame(width: width, height: height, alignment: .top)
          .clipped()
          .overlay {
            LinearGradient(colors: [.white, .clear , .clear, .clear], startPoint: .bottom, endPoint: .top)
          }
        } else {
          if let imageURL = Bundle.main.url(forResource: "FileThumbnail", withExtension: "png"),
            let imageData = try? Data(contentsOf: imageURL),
            let uiImage = UIImage(data: imageData) {
            
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: width, height: height, alignment: .center)
              .clipped()
          }
        }
      }
      .preferredColorScheme(.light)
    }

  func formattedTransactionTotal(_ price: Price, roundingRules: RoundingRuleSet) -> String {
    formattedPrice(price, scale: roundingRules.transactionTotalRule.scale)
  }
  
  func formattedPrice(_ price: Price, scale: Int) -> String {
    price.formatted(.currency(code: document.settings.currencyIdentifier)
      .precision(.fractionLength(scale)))
  }
}



/*
struct TransactionRowView: View {
  
  private static let localizationTable = "TransactionRow"
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
        .foregroundColor(.accentColor)
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
        
        if let counterpartyName = transaction.counterpartyContact?.mainName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
          Text("·").fontWeight(.bold)
          
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            
            Text(counterpartyName)
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
*/



struct DocumentThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
      DocumentThumbnailView(document: .mock(), aspectRatio: 1.4)
      
      DocumentThumbnailView(document: .init(), aspectRatio: 1.4)
    }
}
