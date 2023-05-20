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
    #if os(iOS)
  
//    TransactionMainView()
    TransactionListView()
      .toolbarTitleMenu {
        Text("S")
        RenameButton()
      }
      
    #else
    NavigationSplitView {
      List {
        NavigationLink {
          TransactionListView()
        } label: {
          Label("Transactions", systemImage: "list.bullet.clipboard")
        }
        NavigationLink {
          ItemListView(document: $document.content)
        } label: {
          Label("Items", systemImage: "shippingbox")
        }
        
        NavigationLink {
          ItemTemplateListView(document: $document.content, asSheet: false)
        } label: {
          Label("Item Templates", systemImage: "square.dashed")
        }
        
        Section("Document Settings") {
          CurrencyPicker(currencyIdentifier: $document.content.settings.currencyIdentifier)
        }
      }
    } detail: {
      Text("Select a sidebar item to start")
    }
    #endif
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
