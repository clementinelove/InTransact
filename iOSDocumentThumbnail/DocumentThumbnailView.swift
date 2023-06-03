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
            // I don't think preview is ever gonna contain more than 40 transactions on iOS...?
            ForEach(document.transactions.prefix(40).sorted { $0.date > $1.date } ) { transaction in
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


struct DocumentThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
      DocumentThumbnailView(document: .mock(), aspectRatio: 1.4)
      
      DocumentThumbnailView(document: .init(), aspectRatio: 1.4)
    }
}
