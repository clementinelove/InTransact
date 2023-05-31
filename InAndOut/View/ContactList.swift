//
//  ContactList.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI

struct ContactList: View {
    var body: some View {
      List {
        Text("Name")
        Text("Address")
        Text("Email")
        Text("Phone")
        Text("Tax ID")
        Text("Notes")
      }
    }
}

struct ContactList_Previews: PreviewProvider {
    static var previews: some View {
        ContactList()
    }
}
