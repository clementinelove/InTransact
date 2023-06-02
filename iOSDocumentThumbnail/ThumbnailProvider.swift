//
//  ThumbnailProvider.swift
//  iOSDocumentThumbnail
//
//  Created by Yuhao Zhang on 2023-06-02.
//

import SwiftUI
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    
  @MainActor override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
      
      do {
        let fileData = try Data(contentsOf: request.fileURL)
        let document = try JSONDecoder().decode(INTDocument.self, from: fileData)
        
        let aspectWidth = request.maximumSize.height / DocumentThumbnailView.aspectRatio
        let width = min(request.maximumSize.width, aspectWidth)
        let height = request.maximumSize.height
        let contextSize = CGSize(width: width, height: request.maximumSize.height)
        let expectAspectRatio: Double = height / width
        handler(QLThumbnailReply(contextSize: contextSize, currentContextDrawing: { () -> Bool in
          
          // Draw the thumbnail here.
          if let image = ImageRenderer(content: DocumentThumbnailView(document: document,
                                                                      aspectRatio: expectAspectRatio))
            .uiImage {
            image.draw(in: CGRect(x: 0, y: 0,
                                  width: contextSize.width,
                                  height: contextSize.height))
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
          } else {
            return false
          }
        }), nil)
      } catch {
//        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "FileThumbnail", withExtension: "png")!), nil)
        handler(nil, error)
      }
//    handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "FileThumbnail", withExtension: "png")!), nil)
      
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
//        handler(QLThumbnailReply(contextSize: request.maximumSize, currentContextDrawing: { () -> Bool in
//            // Draw the thumbnail here.
//
//            // Return true if the thumbnail was successfully drawn inside this block.
//            return true
//        }), nil)
        
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
    }
}
