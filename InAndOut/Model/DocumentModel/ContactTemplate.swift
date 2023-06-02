//
//  ContactTemplate.swift
//  iOSDocumentThumbnail
//
//  Created by Yuhao Zhang on 2023-06-02.
//

import Foundation

struct ContactTemplate: Identifiable, Codable, Hashable {
  
  static func ==(lhs: ContactTemplate, rhs: ContactTemplate) -> Bool {
    lhs.name == rhs.name
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
  
  var id: Int {
    hashValue
  }
  var name: String
  var contact: Contact
  
  init(contact: Contact) {
    self.contact = contact
    if contact.isCompany {
      self.name = "\(contact.companyName)"
    } else {
      self.name = "\(contact.name) \(contact.companyName)"
    }
  }
}
