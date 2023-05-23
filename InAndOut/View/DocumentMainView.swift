//
//  DocumentMainView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI

struct DocumentMainView: View {
  
  @EnvironmentObject var document: InTransactDocument
  @Environment(\.undoManager) var undoManager
  
  var body: some View {
    TransactionListView()
  }
}

struct DocumentMainView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DocumentMainView()
        .environmentObject(InTransactDocument.mock())
    }
  }
}
