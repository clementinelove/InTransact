//
//  ItemTemplateEditView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-12.
//

import SwiftUI

class ItemTemplateEditViewModel: ObservableObject {
  @Published var itemName: String = ""
}

struct ItemTemplateEditView: View {
    
//  @StateObject var item
  
    var body: some View {
      Form {
//        TextField("Item Name", text: )
      }
    }
}

struct ItemTemplateEditView_Previews: PreviewProvider {
    static var previews: some View {
        ItemTemplateEditView()
    }
}
