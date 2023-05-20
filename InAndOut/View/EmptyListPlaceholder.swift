//
//  EmptyListPlaceholder.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import SwiftUI

struct EmptyListPlaceholder: View {
  
  let placeholderText: LocalizedStringKey
  init(_ placeholderText: LocalizedStringKey = "Empty") {
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
      if true {
        EmptyListPlaceholder("No Transactions")
      } else {
        List {
          // ...
        }
      }
    }
  }
}
