//
//  DocumentPreviewView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-16.
//

import SwiftUI
import NTPlatformKit

struct DocumentPreviewView: View {
  
  @State var renderedImage: CGImage? = nil
  @ObservedObject var imageRenderer = ImageRenderer(content: Text("Transactions"))
  
  var body: some View {
    VStack {
      Text("Hello, World!")
//      if let renderedImage,
//      let imageData = UIImage(cgImage: renderedImage).pngData() {
//        ShareLink(item: imageData, preview: SharePreview("File", image: Image(renderedImage, scale: 1, label: Text("Image"))))
//      }
    }
    .task(id: 1) {
      let renderer = ImageRenderer(content: DocumentPreviewImage(document: .mock()))
      if let image = renderer.cgImage {
        renderedImage = image
      }
    }
  }
}

struct DocumentPreviewImage: View {
  var document: INODocument
  var body: some View {
    VStack(alignment: .leading) {
      ForEach(document.transactions) { transaction in
        VStack(alignment: .leading) {
          Text("\(transaction.id)")
            .foregroundColor(Global.transactionIDHighlightColor)
            .font(.callout)
          Text("\(transaction.date.formatted(date: .numeric, time: .shortened))")
            .font(.headline)
          Text("\(transaction.total(roundingRules: document.settings.roundingRules).formatted(.currency(code: document.settings.currencyIdentifier)))")
          
        }
        Divider()
      }
    }
    
    .frame(width: 500, height: 500)
    .clipped()
    .border(.red)
    
  }
}

struct DocumentPreviewView_Previews: PreviewProvider {
    static var previews: some View {
      DocumentPreviewImage(document: .mock())
      DocumentPreviewView()
        .environmentObject(InAndOutDocument.mock())
      
    }
}
