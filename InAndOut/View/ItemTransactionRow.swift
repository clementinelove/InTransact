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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
    
    let mainLayout = dynamicTypeSize >= .accessibility1 ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    
    let priceLayout = dynamicTypeSize >= .accessibility1 ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(VStackLayout(alignment: .trailing))
    
    VStack(alignment: .leading, spacing: 10) {
      mainLayout {
        
        VStack(alignment: .leading) {
          Text(displayItemName)
            .foregroundStyle(.primary)
            .font(.headline)
          if let displayVariantName {
            Text(displayVariantName)
              .font(.subheadline)
          }
        }
        
        .multilineTextAlignment(.leading)
        .frame(minWidth: 100, alignment: .topLeading)
        
        
        Spacer()
          .allowsHitTesting(true)
        Text(verbatim:  document.formattedItemSubtotal(itemTransaction.priceInfo.totalAfterTax(taxItemRounding: document.roundingRules.taxItemRule, itemSubtotalRounding: document.roundingRules.itemSubtotalRule)))
          .multilineTextAlignment(.trailing)
      }
      
      // MARK: Tax Details
      VStack(alignment: .leading, spacing: 4) {
        
        Text("\(itemTransaction.priceInfo.quantity) \(Global.timesSymbol) \(pricePerUnitBeforeTaxString)")
        if showTaxDetails {
          ForEach(itemTransaction.priceInfo.regularTaxItems) { taxItem in
            LabeledContent {
              Text(verbatim: "\(document.formattedTaxItem(taxItem.taxCost(of: itemTransaction.priceInfo.totalBeforeTax, rounding: document.roundingRules.taxItemRule)))")
                .foregroundStyle(.secondary)
            } label: {
              Text("\(taxItem.name) (\(taxItem.rate.formatted(.percent)))")
            }
          }
          
          ForEach(itemTransaction.priceInfo.compoundTaxItems) { taxItem in
            LabeledContent {
              Text(verbatim: "\(document.formattedTaxItem(taxItem.taxCost(of: itemTransaction.priceInfo.totalAfterRegularTax(taxItemRounding: document.roundingRules.taxItemRule), rounding: document.roundingRules.taxItemRule)))")
                .foregroundStyle(.secondary)
            } label: {
              Text("\(taxItem.name) (Compound, \(taxItem.rate.formatted(.percent)))")
            }
          }
          
          ForEach(itemTransaction.priceInfo.fixedAmountTaxItems) { taxItem in
            LabeledContent {
              Text(verbatim: "\(taxItem.amount.formatted(.currency(code: document.currencyCode)))")
                .foregroundStyle(.secondary)
            } label: {
              Text("\(taxItem.name) (Fixed Amount Tax)")
            }
          }
        }
      }
      .font(.footnote)
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
