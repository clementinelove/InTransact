//
//  SettingsView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-15.
//

import SwiftUI
import NTPlatformKit

// FIXME: Move currency settings to here!!!
struct DocumentSettingsView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.dismiss) private var dismiss
  @State private var isExpandingTaxItemRoundingSettings = false
  @State private var isExpandingItemSubtotalRoundingSettings = false
  @State private var isExpandingTransactionTotalRoundingSettings = false
  @Binding var settings: Setting
  
  var body: some View {
    Form {
      
      Section {
        NavigationLink {
          CurrencyPickerContent(currencyIdentifier: $settings.currencyIdentifier)
        } label: {
          LabeledContent {
          } label: {
            Text("Document Currency")
            Text("\(document.currencyCode)")
          }
        }
      }
      
      Section {
        roundingRuleSettings(isExpandng: collapseAllFirst($isExpandingTaxItemRoundingSettings),
                             name: "Tax Item",
                             rule: $settings.roundingRules.taxItemRule)
        .accessibilityLabel(Text("Tax Item Rounding"))
        
        roundingRuleSettings(isExpandng: collapseAllFirst($isExpandingItemSubtotalRoundingSettings),
                             name: "Item Subtotal",
                             rule: $settings.roundingRules.itemSubtotalRule)
        .accessibilityLabel(Text("Item Subtotal Rounding"))
        
        roundingRuleSettings(isExpandng: collapseAllFirst( $isExpandingTransactionTotalRoundingSettings),
                             name: "Transaction Total",
                             rule: $settings.roundingRules.transactionTotalRule)
        .accessibilityLabel(Text("Transaction Total Rounding"))
        
        Button {
          settings.resetRoundingToCurrencyDefault()
        } label: {
          VStack(alignment: .leading) {
            Text("Reset Rounding to Currency Default")
            Text("\(RoundingRule.defaultRoundingRule(for: settings.currencyIdentifier).description)")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.borderless)
      } header: {
        Text("Roundings", comment: "Section title of document rounding settings")
      }
    footer: {
      // Tell users that item unit price are not rounded at all. But they are displayed as if they are rounded.
      Text("Each item's unit price and subtotal before tax are not rounded during calculations, so does the fixed amount tax items. They are displayed according to currency's default decimal places.")
    }
    }
    //      .headerProminence(.increased)
    .navigationTitle("Document Settings")
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
  }
  
  func collapseAllFirst(_ bd: Binding<Bool>) -> Binding<Bool> {
    Binding {
      bd.wrappedValue
    } set: { newValue in
      isExpandingTaxItemRoundingSettings = false
      isExpandingItemSubtotalRoundingSettings = false
      isExpandingTransactionTotalRoundingSettings = false
      bd.wrappedValue = newValue
    }
  }
  
  func roundingRuleSettings(isExpandng: Binding<Bool>,
                            name: LocalizedStringKey,
                            rule: Binding<RoundingRule>) -> some View {
    
    DisclosureGroup(isExpanded: isExpandng) {
      Picker("Rounding Method", selection: rule.mode) {
        ForEach(RoundingMode.allCases, id: \.hashValue) { mode in
          Text(mode.description)
            .tag(mode)
        }
      }
      decimalPrecisionSlider(rule)
    } label: {
      VStack(alignment: .leading) {
        Text(name)
        Text("\(rule.wrappedValue.mode.description), \(rule.wrappedValue.scale.description) Decimal Places")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  func decimalPrecisionSlider(_ ruleBinding: Binding<RoundingRule>) -> some View {
    //    document.content.settings.roundingRules.taxItemRule
    VStack(alignment: .leading) {
      Text("Decimals:  \(ruleBinding.wrappedValue.scale)")
      Slider(value: Binding<Double>(get: {
        Double(ruleBinding.wrappedValue.scale)
      }, set: { newValue in
        ruleBinding.wrappedValue.scale = Int(newValue)
      }) , in: 0.0...10.0, step: 1) {
        Text("Precision")
      } minimumValueLabel: {
        Text("0")
      } maximumValueLabel: {
        Text("10")
      }
      // 1232.5463
      Text("Preview: \(Decimal(string: "365.065")!.rounded(using: ruleBinding.wrappedValue).formatted(.currency(code: settings.currencyIdentifier ).precision(.fractionLength(ruleBinding.wrappedValue.scale))))")
    }
  }
}

struct DocumentSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle().sheet(isPresented: .constant(true)) {
      NavigationStack {
        DocumentSettingsView(settings: .constant(Setting()))
          .environmentObject(InTransactDocument.mock())
      }
    }
  }
}
