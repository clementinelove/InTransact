//
//  ItemTemplateListView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-12.
//

import SwiftUI

struct ItemTemplateListView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.dismiss) private var dismiss
  @State private var selectedTemplate: ItemTemplate? = nil
  @State private var searchText: String = ""
  
  let asSheet: Bool
  var onSelect: ((ItemTemplate) -> Void)? = nil
  
  var body: some View {
    List {
      ForEach(document.content.itemTemplates.sorted { $0.variantName < $1.variantName } ) { template in
        
        Button {
          selectedTemplate = template
        } label: {
          ItemTemplateRow(itemTemplate: template)
        }
        .foregroundStyle(.primary)
      }
    }
    .sheet(item: $selectedTemplate) { template in
      NavigationStack {
        ItemTemplateDetailView(itemTemplate: template, parentDismiss: dismiss, onApply: onSelect)
          
          #if os(iOS)
.toolbarRole(.navigationStack)
#endif
      }
    }
    .overlay {
      ItemTemplateSearchResultListView(searchText: $searchText, selectedTemplate: $selectedTemplate)
        
    }
    .searchable(text: $searchText)
    .toolbar {
      if asSheet {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .navigationTitle("Templates")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    // MARK: View End
  }
}

struct ItemTemplateSearchResultListView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.isSearching) private var isSearching
  
  @Binding var searchText: String
  @Binding var selectedTemplate: ItemTemplate?
  
  var filteredTemplates: [ItemTemplate] {
    let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return document.content.itemTemplates.filter {
      $0.itemID?.lowercased().contains(trimmedSearchText) ?? false || $0.itemName.lowercased().contains(trimmedSearchText) || $0.variantName.contains(trimmedSearchText)
    }
    
    // TODO: sort the result
  }
  
  var body: some View {
    if isSearching && !searchText.isEmpty {
      List {
        ForEach(filteredTemplates) { template in
          
          Button {
            selectedTemplate = template
          } label: {
            ItemTemplateRow(itemTemplate: template)
          }
          .foregroundStyle(.primary)
        }
      }
    }
  }
}

struct ItemTemplateDetailView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.dismiss) private var dismiss
  let itemTemplate: ItemTemplate
  var parentDismiss: DismissAction?
  var onApply: ((ItemTemplate) -> Void)?
  
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading) {
          Text(itemTemplate.itemName)
            .font(.title.bold())
            .lineLimit(nil)
          Text(itemTemplate.variantName)
            .font(.title3)
        }
        .padding(.bottom, 20)
        .listRowSeparator(.hidden)
      }
      
      Section {
        LabeledContent("Quantity") {
          Text("\(itemTemplate.priceInfo.quantity)")
            .textSelection(.enabled)
        }
        .foregroundStyle(.primary)
        
        LabeledContent("Price Per Unit (Before Tax)") {
          Text(itemTemplate.priceInfo.pricePerUnitBeforeTax.formatted(.currency(code: document.currencyCode)))
            .textSelection(.enabled)
        }
        .foregroundStyle(.primary)
        
        LabeledContent("Price Per Unit (After Tax)") {
          VStack(alignment: .trailing, spacing: 4) {
            Text(verbatim: itemTemplate
              .priceInfo
              .pricePerUnitAfterTax(taxItemRounding: document.roundingRules.taxItemRule,
                             totalRounding: document.roundingRules.transactionTotalRule)
                .formatted(.currency(code: document.currencyCode)))
            .textSelection(.enabled)
          }
        }
        .foregroundStyle(.primary)
        
        
        LabeledContent("Total Before Tax") {
          VStack(alignment: .trailing, spacing: 4) {
            // No need to round
            Text(verbatim: itemTemplate.priceInfo.totalBeforeTax.formatted(.currency(code: document.currencyCode)))
              .font(.body)
              .textSelection(.enabled)
          }
        }
        .foregroundStyle(.primary)
        
        regularTaxItems
        compoundTaxItems
        fixedTaxItems
        
        LabeledContent("Total After Tax") {
          VStack(alignment: .trailing, spacing: 4) {
            Text(verbatim: document.formattedItemTotal(itemTemplate
              .priceInfo
              .totalAfterTax(taxItemRounding: document.roundingRules.taxItemRule,
                             itemTotalRounding: document.roundingRules.transactionTotalRule)))
            .font(.body)
            .textSelection(.enabled)
          }
        }
        .foregroundStyle(.primary)
      } footer: {
        Text("When the price type used in the template is not an after tax unit price, the price per unit (after tax) is calculated using the after tax item total divides the quantity.")
          .fontWeight(.medium)
          
      }
      .listSectionSeparator(.hidden)
    }
    .safeAreaInset(edge: .bottom) {
      if let onApply, let parentDismiss {
        HStack {
          Button {
            parentDismiss()
            onApply(itemTemplate)
          } label: {
            Text("Apply This Template")
              .font(.headline)
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Material.ultraThin)
      }
    }
    .listStyle(.inset)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        doneButton
      }
    }
  }
  
  var regularTaxItems: some View {
    Group {
      ForEach(itemTemplate.priceInfo.regularTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Regular Tax")
            .font(.caption2)
          
          LabeledContent {
            Text(verbatim: document.formattedTaxItem(taxItem.taxCost(of: itemTemplate.priceInfo.totalBeforeTax, rounding: document.roundingRules.taxItemRule)))
          } label: {
            Text(verbatim: "\(taxItem.name) (\(taxItem.rate.formatted(.percent)))")
          }
          .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var compoundTaxItems: some View {
    Group {
      
      ForEach(itemTemplate.priceInfo.compoundTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Compound Tax")
            .font(.caption2)
          LabeledContent {
            Text(verbatim: document.formattedTaxItem(taxItem.taxCost(of: itemTemplate.priceInfo.totalAfterRegularTax(taxItemRounding: document.roundingRules.taxItemRule), rounding: document.roundingRules.taxItemRule)))
          } label: {
            Text(verbatim: "\(taxItem.name) (\(taxItem.rate.formatted(.percent)))")
          }
          .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var fixedTaxItems: some View {
    Group {
      
      ForEach(itemTemplate.priceInfo.fixedAmountTaxItems) { taxItem in
        VStack(alignment: .leading) {
          Text("Fixed Tax")
            .font(.caption2)
          
          LabeledContent {
            Text(verbatim: taxItem.amount.formatted(.currency(code: document.currencyCode)))
          } label: {
            Text(verbatim: "\(taxItem.name)")
          }
          .foregroundStyle(.primary)
        }
      }
    }
  }
  
  var doneButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(.gray, .gray.opacity(0.2))
        .imageScale(.large)
    }
    .buttonStyle(.plain)
  }
}

struct ItemTemplateListView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        ItemTemplateListView(asSheet: true) { _ in }
          .environmentObject(InTransactDocument.mock())
      }
      .previewDisplayName("Item Templates")
      
      ItemTemplateDetailView(itemTemplate: .mock())
        .environmentObject(InTransactDocument.mock())
    }
}
