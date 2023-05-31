//
//  VerticalField.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI

struct VerticalField<LabelView: View, ContentView: View>: View {
  var content: () -> ContentView
  var label: () -> LabelView
  
  var body: some View {
      VStack(alignment: .leading, spacing: 3) {
        label()
          .font(.caption)
          .multilineTextAlignment(.leading)
        content()
      }
    }
}

extension VerticalField where LabelView == Text {
  init(_ title: LocalizedStringKey, content: @escaping () -> ContentView) {
    self.label = { Text(title) }
    self.content = content
  }
}

struct VerticalField_Previews: PreviewProvider {
    static var previews: some View {
      HStack(alignment: .firstTextBaseline) {
        VerticalField("Title") {
          TextField("Hi!", text: .constant("This is nice"))
        }
        
        VStack(alignment: .leading){
          Text("Title")
            .font(.subheadline)
          Text("This is nice")
        }
      }
    }
}
