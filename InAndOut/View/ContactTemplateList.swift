//
//  ContactTemplateList.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI
import OrderedCollections

struct ContactTemplateList: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @State private var contactTemplates: OrderedSet<ContactTemplate> = OrderedSet((0...20).map({ _ in
      .mock()
  }))
  @State private var searchText: String = ""
  @State private var selectedTemplate: ContactTemplate? = nil
  
    var body: some View {
      List {
        ForEach(contactTemplates, id: \.hashValue) { template in
          row(template)
        }
      }
      .overlay {
        if !searchText.isEmpty {
          List {
            ForEach(contactTemplates.filter({ $0.contact.textContains(searchText)
            }), id: \.hashValue) { template in
              row(template)
            }
          }
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                dismiss()
              }
            }
          }
        }
      }
      .searchable(text: $searchText)
      .navigationTitle("Saved Contacts")
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .sheet(item: $selectedTemplate) {
        selectedTemplate = nil
      } content: { template in
        NavigationStack {
          ScrollView {
            ContactView(contact: template.contact)
              .padding()
          }
          .safeAreaInset(edge: .bottom, content: {
            Button("Use") {
              // ...
            }
            
          })
            
#if os(iOS)
            .toolbarRole(.navigationStack)
#endif
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  selectedTemplate = nil
                }
              }
            }
        }
        .presentationDetents([.medium])

      }
    }
  
  @ViewBuilder
  func row(_ template: ContactTemplate) -> some View {
    let contact = template.contact
    Button {
      selectedTemplate = template
    } label: {
      VStack(alignment: .leading) {
        Text(verbatim: !contact.isCompany ? "\(contact.name)" : "\(contact.companyName)" )
          .lineLimit(1)
          .font(.headline)
        
        Text(verbatim: contact.companyName)
          .lineLimit(1)
          .font(.subheadline)
          .foregroundStyle(contact.isCompany ? .primary : .secondary)
          .lineLimit(1)
          .opacity(contact.isCompany ? 0 : 1)
      }
    }
    .foregroundStyle(.primary)
  }
}

struct ContactTemplateList_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        ContactTemplateList()
      }
    }
}
