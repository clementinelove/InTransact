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
  
  var body: some Scene {
    DocumentGroup(newDocument: { InTransactDocument() } ) { configuration  in
      //            ContentView(document: file.$document)
      TransactionListView(documentName: fileName)
        .task(id: configuration.fileURL) {
          if let fileURL = configuration.fileURL,
             let percentDecodedFileName = fileURL.lastPathComponent.removingPercentEncoding {
            let seperatedFileName = percentDecodedFileName.split(separator: ".", maxSplits: Int.max)
            let newFileName = seperatedFileName.dropLast(1).joined(separator: ".")
            fileName = newFileName
            logger.debug("New File Name: \(newFileName)")
          } else {
            fileName = nil
          }
        }
        
      // TODO: add first time feature introduction popup
    }
  }
}
