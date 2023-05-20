//
//  DocumentMainView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import SwiftUI

struct DocumentMainView: View {
  
  @EnvironmentObject var document: InAndOutDocument
  @Environment(\.undoManager) var undoManager
  
  var body: some View {
    TransactionListView()
//    #if os(iOS)
//
//    TransactionListView()
//
//    #else
//    NavigationSplitView {
//      List {
//
//      }
//    } detail: {
//      Text("Select a sidebar item to start")
//    }
//    #endif
  }
}

struct DocumentMainView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DocumentMainView()
        .environmentObject(InAndOutDocument.mock())
    }
  }
}
