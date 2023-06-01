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
  @AppStorage("isFirstUse") private var isFirstUse: Bool?
  
  var body: some Scene {
    DocumentGroup(newDocument: { InTransactDocument() } ) { configuration  in
      //            ContentView(document: file.$document)
      DocumentMainView(fileURL: fileURL)
        .task(id: configuration.fileURL) {
          fileURL = configuration.fileURL
        }
        .sheet(isPresented: Binding(get: {
          isFirstUse == nil || isFirstUse == true
        }, set: { dismiss in
          isFirstUse = false
        }), onDismiss: {
          Task { @MainActor in
            isFirstUse = false
          }
        }) {
          WelcomeView()
        }
    }
  }
}
