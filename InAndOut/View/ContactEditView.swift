//
//  ContactEditView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI
import NTPlatformKit

struct ContactEditView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var document: InTransactDocument
  @Binding var contact: Contact
  @State private var magicHappens: Bool = false
  
  var body: some View {
    Form {
      // TODO: Future - copy from templates
//      Section {
//
//      }
      Section {
        
        Picker(selection: $contact.isCompany.animated) {
          Text("Individual", comment: "Individual Contact Type")
            .tag(false)
          Text("Company", comment: "Company Contact Type")
            .tag(true)
        } label: {
          Text("Contact Type")
        }
        
        if !contact.isCompany {
          TextField(String(localized: "Name", comment: "Name of the counterparty contact"), text: $contact.name)
          #if os(iOS)
            .keyboardType(.namePhonePad)
          #endif
        }
        
        TextField("Company Name", text: $contact.companyName)
        
        
        TextField("Phone Number", text: $contact.phoneNumber)
#if os(iOS)
          .keyboardType(.phonePad)
#endif
        
        TextField("Email", text: $contact.email)
#if os(iOS)
          .keyboardType(.emailAddress)
#endif
        
        TextField("Account", text: $contact.account)
        TextField("Tax ID", text: $contact.taxID)
      }
      
      Section("Address") { // Postal Address
        TextEditor(text: $contact.address)
        #if os(iOS)
          .textContentType(.location)
        #endif
          .frame(minHeight: 100, alignment: .topLeading)
      }
      
      Section("Notes") {
        TextEditor(text: $contact.notes)
          .frame(minHeight: 120, alignment: .topLeading)
      }
      
      // TODO: future - save as template
//      Section {
//        Toggle("Save Contact For Future Use", isOn: .constant(true))
//      } footer: {
//        Text("This will override existing contact template with the same name.")
//      }
    }
    .onAppear {
      // This is so stupid: SwiftUI won't behave properly when nothing happens in a view, it just needs something to happen to the binding to be able to animate properly, really annoying. If you remove this line, the animation triggered by 'Done' button would be stutter again
      contact = contact
    }
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
  }
}

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

struct ContactEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ContactEditView(contact: .constant(.fresh()))
        .environmentObject(InTransactDocument.mock())
    }
  }
}
