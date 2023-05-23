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
    DocumentGroup(newDocument: { InTransactDocument() } ) { configuration  in
      //            ContentView(document: file.$document)
      DocumentMainView()
        
      // TODO: add first time feature introduction popup
    }
  }
}
