//
//  CurrencyPickerContent.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import SwiftUI

struct CurrencyPickerContent: View {
  
  @Binding var currencyIdentifier: String
  @State private var searchText: String = ""
  @Environment(\.dismiss) private var dismiss
  @Environment(\.undoManager) private var undoManager
  
  var body: some View {
    List {
      if let currentLocaleCurrencyIdentifier = Locale.current.currency?.identifier {
        Picker(selection: currencyCodeAutoDismissBinding) {
          currencyRow(currentLocaleCurrencyIdentifier)
        } label: {
          Text("Current System Locale")
        }
        .pickerStyle(.inline)
      }
      
      Section {
        Picker(selection: currencyCodeAutoDismissBinding) {
          ForEach(Locale.commonISOCurrencyCodes, id: \.self) { currencyCode in
            currencyRow(currencyCode)
          }
        } label: {
          
        }
        .pickerStyle(.inline)
      }
    }
    .overlay {
      if !searchText.isEmpty {
        List {
          Picker(selection: currencyCodeAutoDismissBinding) {
            ForEach(Locale.commonISOCurrencyCodes.filter({ code in
              code.localizedStandardContains(code)
            }), id: \.self) { currencyCode in
              if currencyCode.description.localizedStandardContains(searchText) ||
                  localizedCurrenyCode(currencyCode).localizedStandardContains(searchText) {
                currencyRow(currencyCode)
              }
            }
          } label: {
          }
          .pickerStyle(.inline)
        }
      }
    }
#if os(iOS)
    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    .navigationBarTitleDisplayMode(.inline)
#elseif os(macOS)
    // TODO: make it searchable on macOS
#endif
    .navigationTitle("Currency")
    
  }
  
  func currencyRow(_ currencyCode: String) -> some View {
    VStack(alignment: .leading) {
      Text(currencyCode)
      Text(localizedCurrenyCode(currencyCode))
        .font(.caption)
    }
    .tag(currencyCode)
  }
  
  var currencyCodeAutoDismissBinding: Binding<String> {
    Binding(get: {currencyIdentifier},
            set: { newVaue in
      currencyIdentifier = newVaue;
      dismiss()
    })
  }
  
  func localizedCurrenyCode(_ currencyCode: String) -> String {
    Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? "Unknown"
  }
}
