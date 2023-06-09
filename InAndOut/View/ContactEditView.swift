//
//  ContactEditView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI
import NTPlatformKit

struct ContactEditView: View {
  
  let undoManager: UndoManager?
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var document: InTransactDocument
  @Binding var contact: Contact
  @State private var magicHappens: Bool = false
  @State private var saveContactForFutureUse: Bool = false
  @State private var isShowingSavedContacts = false
  
  var body: some View {
    Form {
      
      // MARK: Copy from templates
      if document.content.contactTemplates.count > 0 {
        Section {
          Button {
            isShowingSavedContacts = true
          } label: {
            Label {
              Text("Select from Saved Contacts", comment: "Button to show the list of saved contacts")
            } icon: {
              Image(systemName: "plus.square.on.square")
            }
          }
        }
      }
      
      
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
      
      // MARK: Save as template
      Section {
        Toggle("Save Contact For Future Use", isOn: $saveContactForFutureUse)
      } footer: {
        Text("This will override existing contact template with the same name.")
      }
    }
    .onAppear {
      // This is so stupid: SwiftUI won't behave properly when nothing happens in a view, it just needs something to happen to the binding to be able to animate properly, really annoying. If you remove this line, the animation triggered by 'Done' button would be stutter again
      contact = contact
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          if saveContactForFutureUse {
            if let compactedContact = contact.compacted {
              document.saveContact(compactedContact, undoManager: undoManager)
            }
          }
          dismiss()
        }
      }
    }
    .sheet(isPresented: $isShowingSavedContacts) {
      NavigationStack {
        SavedContactTemplateList { selectedContact in
          contact = selectedContact
        }
        #if os(iOS)
        .toolbarRole(.navigationStack)
        #endif
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Done") {
              isShowingSavedContacts = false
            }
          }
        }
      }
    }
    
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
  }
}

struct ContactEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ContactEditView(undoManager: UndoManager(), contact: .constant(.fresh()))
        .environmentObject(InTransactDocument.mock())
    }
  }
}
