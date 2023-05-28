//
//  SettingsView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-15.
//

import SwiftUI

struct DocumentSettingsView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.undoManager) private var undoManager
  @Environment(\.dismiss) private var dismiss
  @State private var isExpandingTaxItemRoundingSettings = false
  @State private var isExpandingItemTotalRoundingSettings = false
  @State private var isExpandingTransactionTotalRoundingSettings = false
  @State private var settings: Setting = Setting()
  
  init(document: InTransactDocument) {
    // copy settings
    _settings = State(wrappedValue: document.content.settings)
  }
  
  var body: some View {
    Form {
      
//      Section("Defaults") {
//        TextField("Keeper Name", text: .constant(""))
//        TextField("Regular Tax", text: .constant(""))
//      }
      
      Section {
        roundingRuleSettings(isExpandng: collapseAllFirst($isExpandingTaxItemRoundingSettings),
                             name: "Tax Item",
                             rule: $settings.roundingRules.taxItemRule)
        .accessibilityLabel(Text("Tax Item Rounding"))
        
        roundingRuleSettings(isExpandng: collapseAllFirst($isExpandingItemTotalRoundingSettings),
                             name: "Item Total",
                             rule: $settings.roundingRules.itemTotalRule)
        .accessibilityLabel(Text("Item Total Rounding"))
        
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
        Text("Rounding")
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
    .onDisappear {
      withAnimation {
        document.updateSettings(settings, undoManager: undoManager)
      }
    }
  }
  
  func collapseAllFirst(_ bd: Binding<Bool>) -> Binding<Bool> {
    Binding {
      bd.wrappedValue
    } set: { newValue in
      isExpandingTaxItemRoundingSettings = false
      isExpandingItemTotalRoundingSettings = false
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
      Text("Preview: \(Decimal(string: "1.065")!.rounded(using: ruleBinding.wrappedValue).formatted(.currency(code: settings.currencyIdentifier ).precision(.fractionLength(ruleBinding.wrappedValue.scale))))")
    }
  }
}

struct DocumentSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle().sheet(isPresented: .constant(true)) {
      NavigationStack {
        DocumentSettingsView(document: .mock())
          .environmentObject(InTransactDocument.mock())
      }
    }
  }
}
