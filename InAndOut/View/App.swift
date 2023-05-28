//
//  InAndOutApp.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import os.log

fileprivate let logger = Logger(subsystem: Global.subsystem, category: "App")

@main
struct InAndOutApp: App {
  
  @State private var fileName: String? = nil
  @State private var fileURL: URL? = nil
  
  var body: some Scene {
    DocumentGroup(newDocument: { InTransactDocument() } ) { configuration  in
      //            ContentView(document: file.$document)
      DocumentMainView(fileURL: fileURL)
        .task(id: configuration.fileURL) {
          fileURL = configuration.fileURL
        }
        
      // TODO: add first time feature introduction popup
    }
  }
}
