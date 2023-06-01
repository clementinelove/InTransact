//
//  ItemTemplateRow.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-20.
//

import SwiftUI

struct ItemTemplateRow: View {
  @EnvironmentObject private var document: InTransactDocument
  let itemTemplate: ItemTemplate
  
  static let itemIDPlaceholder = String(localized: "No Item ID", comment: "Item ID Placeholder in template row")
  static let itemNamePlaceholder = String(localized: "Unnamed Item", comment: "Item Name Placeholder in template row")
  static let variantNamePlaceholder = String(localized: "Unnamed Variant", comment: "Item Name Placeholder in template row")
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      
      Text("\(itemTemplate.itemID?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? Self.itemIDPlaceholder)".uppercased())
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
      
      VStack(alignment: .leading) {
        HStack {
          Text(itemTemplate.itemName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? Self.itemNamePlaceholder)
            .foregroundStyle(.primary)
          Spacer()
          Text("\(itemTemplate.priceInfo.pricePerUnitBeforeTax.formatted(.currency(code: document.currencyCode)))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Text(itemTemplate.variantName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? Self.variantNamePlaceholder)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct ItemTemplateRow_Previews: PreviewProvider {
  static var previews: some View {
    List {
      ForEach(0..<10) { _ in
        ItemTemplateRow(itemTemplate: .mock())
      }
      
    }
      .environmentObject(InTransactDocument.mock())
  }
}
