//
//  TransactionFilterBadge.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import SwiftUI

struct TransactionFilterBadge: View {
    
  @Binding var filteredItemName: String
  
    var body: some View {
      VStack(alignment: .leading) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Filtering")
              .font(.footnote.smallCaps())
              .foregroundStyle(.secondary)
              .lineLimit(1)
            
            Text(filteredItemName)
              .font(.headline)
              .lineLimit(1)
          }
          
          Spacer()
          Button {
            removeFilter()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.gray, .gray.opacity(0.2))
          }
        }
        
      }
      .padding(.horizontal)
      .padding(.top, 8)
      .padding(.bottom, 10)
      .background(.thinMaterial)
    }
  
  private func removeFilter() {
    withAnimation {
      filteredItemName = ""
    }
  }
}

struct TransactionFilterBadge_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        List {
          ForEach(0..<100) { i in
            Text(verbatim: "Okay \(i)")
          }
          .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .searchable(text: .constant(""))
        .safeAreaInset(edge: .top) {
          TransactionFilterBadge(filteredItemName: .constant("Fast Noodle"))
        }
      }
        
    }
}
