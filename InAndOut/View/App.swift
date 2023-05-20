//
//  InAndOutApp.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI

@main
struct InAndOutApp: App {
  
  var body: some Scene {
    DocumentGroup(newDocument: { InAndOutDocument() } ) { configuration  in
      //            ContentView(document: file.$document)
      DocumentMainView()
        
      // TODO: add document currency code
      // TODO: add first time feature introduction popup
    }
  }
}
