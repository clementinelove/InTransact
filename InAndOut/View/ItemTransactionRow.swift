//
//  ItemTransactionRow.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import NTPlatformKit

struct ItemTransactionRow: View {
  @EnvironmentObject private var document: InTransactDocument
  @Binding var itemTransaction: ItemTransaction
  
  var showTaxDetails = false
  
  static let emptyItemNamePlaceholder = String(localized: "Unknown Item Name", comment: "Placeholder for empty item name") 
  
  var displayItemName: String {
    let trimmed = itemTransaction.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return Self.emptyItemNamePlaceholder
    } else {
      return trimmed
    }
  }
  
  var displayVariantName: String? {
    guard let variant = itemTransaction.variant else { return nil }
    let trimmed = variant.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return nil
    } else {
      return trimmed
    }
  }
  
  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 10) {
        VStack(alignment: .leading) {
          Text(displayItemName)
            .foregroundStyle(.primary)
            .font(.headline)
          if let displayVariantName {
            Text(displayVariantName)
              .font(.subheadline)
          }
        }
      }
      .multilineTextAlignment(.leading)
      
      Spacer()
        .allowsHitTesting(true)
      
      VStack(alignment: .trailing, spacing: 3) {
        Text(verbatim:  document.formattedItemTotal(itemTransaction.priceInfo.totalAfterTax(taxItemRounding: document.roundingRules.taxItemRule, itemTotalRounding: document.roundingRules.itemTotalRule)))
          .multilineTextAlignment(.trailing)

        // MARK: Tax Details
        VStack(alignment: .trailing) {
          
          Text("\(itemTransaction.priceInfo.quantity) \(Global.timesSymbol) \(pricePerUnitBeforeTaxString)")
          if showTaxDetails {
            ForEach(itemTransaction.priceInfo.regularTaxItems) { taxItem in
              Text(verbatim: "\(taxItem.name) (\(taxItem.rate.formatted(.percent))) \(document.formattedTaxItem(taxItem.taxCost(of: itemTransaction.priceInfo.totalBeforeTax, rounding: document.roundingRules.taxItemRule)))")
                .foregroundStyle(.secondary)
            }
            
            ForEach(itemTransaction.priceInfo.compoundTaxItems) { taxItem in
              Text(verbatim: "\(taxItem.name) (\(taxItem.rate.formatted(.percent))) \(document.formattedTaxItem(taxItem.taxCost(of: itemTransaction.priceInfo.totalAfterRegularTax(taxItemRounding: document.roundingRules.taxItemRule), rounding: document.roundingRules.taxItemRule)))")
                .foregroundStyle(.secondary)
            }
            
            ForEach(itemTransaction.priceInfo.fixedAmountTaxItems) { taxItem in
              Text(verbatim: "\(taxItem.name) \(taxItem.amount.formatted(.currency(code: document.currencyCode)))")
                .foregroundStyle(.secondary)
            }
          }
        }
        .font(.footnote)
      }
      .layoutPriority(1)
    }
  }
  
  var pricePerUnitBeforeTaxString: String {
    // No need to round, use currency's default rounding precision and rounding rule.
    let pricePerUnitString = itemTransaction.priceInfo.pricePerUnitBeforeTax.formatted(.currency(code: document.currencyCode))
    
    if itemTransaction.priceInfo.canOnlyCalculateAveragePrice {
      return "Avg. \(pricePerUnitString)"
    } else {
      return pricePerUnitString
    }
  }
}

struct ItemTransactionRow_Previews: PreviewProvider {
  static var previews: some View {
    List {
      ForEach(0..<50) { _ in
        ItemTransactionRow(itemTransaction: .constant(.mock()))
        ItemTransactionRow(itemTransaction: .constant(.mock()), showTaxDetails: true)
      }
    }
    .listStyle(.plain)
    .environmentObject(InTransactDocument.mock())
    .previewDisplayName("Plain")
    
    
    List {
      ForEach(0..<50) { _ in
        
        ItemTransactionRow(itemTransaction: .constant(.mock()))
        
      ItemTransactionRow(itemTransaction: .constant(.mock()), showTaxDetails: true)
      }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #endif
    .environmentObject(InTransactDocument.mock())
    .previewDisplayName("Inset Grouped")
      
  }
}
