//
//  CurrencyTextField.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-17.
//

import SwiftUI

// TODO: maybe replace 0 with empty string when editing?
struct CurrencyTextField<FocusValue: Hashable>: View {
  
  @EnvironmentObject private var document: InAndOutDocument
  @Binding var amount: Decimal
  var focusedBinding: FocusState<FocusValue?>.Binding
  let value: FocusValue
  var alignment: TextAlignment = .leading
  
  var body: some View {
      ZStack(alignment: zStackAlignment) {
        TextField("", value: $amount, format: .number.sign(strategy: .never))
          .focused(focusedBinding, equals: value)
          .onSubmit {
            focusedBinding.wrappedValue = nil
            amount = abs(amount)
          }
          .opacity(focusedBinding.wrappedValue == value ? 1 : 0)
          .multilineTextAlignment(alignment)
        
        
        Text(Decimal.FormatStyle.Currency.currency(code: document.currencyCode).format(amount))
          .opacity(focusedBinding.wrappedValue == value ? 0 : 1)
          .multilineTextAlignment(alignment)
          .frame(maxWidth: .infinity, alignment: zStackAlignment)
          .contentShape(Rectangle())
          .onTapGesture {
            focusedBinding.wrappedValue = value
          }
          
      }
//      .border(focusedBinding.wrappedValue == value ? .red : .blue)// for testing
  }
  
  var zStackAlignment: Alignment {
    switch alignment {
      case .leading:
        return .leadingFirstTextBaseline
      case .center:
        return .centerFirstTextBaseline
      case .trailing:
        return .trailingFirstTextBaseline
    }
  }
}

struct CurrencyTextField_PreviewWrapper: View {
  
  enum Field {
    case sample
  }
  
  @State var amount: Decimal = 0.0
  @FocusState var field: Field?
  
  var body: some View {
    CurrencyTextField(amount: $amount,
                      focusedBinding: $field, value: .sample)
    CurrencyTextField(amount: $amount,
                      focusedBinding: $field, value: .sample,
                      alignment: .trailing)
  }
}

/// This view only works fine in navigation stack
struct CurrencyTextField_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        CurrencyTextField_PreviewWrapper()
      }
    }
}
