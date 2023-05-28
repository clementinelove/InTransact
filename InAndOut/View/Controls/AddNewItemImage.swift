//
//  AddNewItemImage.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-28.
//

import SwiftUI

struct AddNewItemImage: View {
    var body: some View {
      Image(systemName: "plus.circle.fill")
        .foregroundStyle(.white, .green)
    }
}

struct AddNewItemImage_Previews: PreviewProvider {
    static var previews: some View {
        AddNewItemImage()
    }
}
