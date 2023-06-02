//
//  Contact.swift
//  iOSDocumentThumbnail
//
//  Created by Yuhao Zhang on 2023-06-02.
//

import Foundation
import NTPlatformKit

struct Contact: Codable, Hashable {
  
  var isCompany: Bool
  var name: String
  var companyName: String
  var email: String
  var phoneNumber: String
  
  var account: String
  var taxID: String
  
  var address: String
  
  var notes: String
  
  var mainName: String {
    if isCompany {
      return companyName
    } else {
      return name
    }
  }
  
  var compacted: Contact? {
    guard !isAllEmpty else { return nil }
    
    var contact = self
    if isCompany {
      contact.name = ""
    } else {
      contact.name = name.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    }
    contact.companyName = companyName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.email = email.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.phoneNumber = phoneNumber.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.account = account.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.taxID = taxID.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.address = address.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    contact.notes = notes.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines)
    return contact
  }
  
  static func fresh() -> Contact {
    Contact(isCompany: false, name: "", companyName: "", email: "", phoneNumber: "", account: "", taxID: "", address: "", notes: "")
  }
  
  var isAllEmpty: Bool {
    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !hasDetails
  }
  
  var hasDetails: Bool {
    !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
    !taxID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
    !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
    !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  func textContains(_ searchText: String) -> Bool {
    return self.name.localizedStandardContains(searchText) ||
    self.companyName.localizedStandardContains(searchText) ||
    self.taxID.localizedStandardContains(searchText) ||
    self.notes.localizedStandardContains(searchText) ||
    self.phoneNumber.localizedStandardContains(searchText) ||
    self.email.localizedStandardContains(searchText) ||
    self.address.localizedStandardContains(searchText)
  }
}
