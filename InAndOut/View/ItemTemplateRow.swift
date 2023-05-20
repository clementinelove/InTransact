//
//  ItemTemplateRow.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-20.
//

import SwiftUI

struct ItemTemplateRow: View {
  @EnvironmentObject private var document: InAndOutDocument
  let itemTemplate: ItemTemplate
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      
      Text("\(itemTemplate.itemID?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? "No Item ID")".uppercased())
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
      
      VStack(alignment: .leading) {
        HStack {
          Text(itemTemplate.itemName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? "(Unnamed Item)")
            .foregroundStyle(.primary)
          Spacer()
          // FIXME: was price before tax
          Text("\(itemTemplate.priceInfo.pricePerUnitBeforeTax.formatted(.currency(code: document.currencyCode)))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Text(itemTemplate.variantName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? "(Unnamed Variant)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        // TODO: grammar agreement plural here
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
      .environmentObject(InAndOutDocument.mock())
  }
}
