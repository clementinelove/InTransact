//
//  EmptyListPlaceholder.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import SwiftUI

/// Use it using if else branches with List
struct EmptyListPlaceholder: View {
  
  let placeholderText: LocalizedStringKey
  // FIXME: in locale
  init(_ placeholderText: LocalizedStringKey = "Empty List") {
    self.placeholderText = placeholderText
  }
  
  var body: some View {
    Text(placeholderText)
      .font(.title3)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct EmptyListPlaceholder_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      EmptyListPlaceholder("No Transactions")
    }
  }
}
