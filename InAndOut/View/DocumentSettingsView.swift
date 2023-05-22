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
  
    var body: some View {
      Form {
        
// ...
        Text("No Settings")
      }
      .navigationTitle("Document Settings")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
}

struct DocumentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
      Rectangle().sheet(isPresented: .constant(true)) {
        NavigationStack {
          DocumentSettingsView()
            .environmentObject(InTransactDocument.mock())
        }
      }
    }
}
