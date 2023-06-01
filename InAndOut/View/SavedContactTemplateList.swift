//
//  ContactTemplateList.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI
import OrderedCollections

struct SavedContactTemplateList: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject var document: InTransactDocument
  
  @State private var searchText: String = ""
  @State private var selectedTemplate: ContactTemplate? = nil
  var onApply: ((Contact) -> Void)?
  
    var body: some View {
      List {
        ForEach(document.content.contactTemplates, id: \.hashValue) { template in
          row(template)
        }
      }
      .overlay {
        if !searchText.isEmpty {
          List {
            ForEach(document.content.contactTemplates.filter({ $0.contact.textContains(searchText)
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
        // MARK: Template Details
        NavigationStack {
          ScrollView {
            ContactView(contact: template.contact)
              .padding(.vertical)
              .padding(.horizontal, 32)
          }
          .safeAreaInset(edge: .bottom, content: {
            Button {
              onApply?(template.contact)
              dismiss()
            } label: {
              Text("Apply", comment: "Button to apply a contact template")
                .font(.headline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical)
            .padding(.horizontal, 32)
            .background(Material.thick)
          })
            
#if os(iOS)
            .toolbarRole(.navigationStack)
#endif
            .toolbar {
              ToolbarItem(placement: .primaryAction) {
                Button {
                  selectedTemplate = nil
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray, .gray.opacity(0.2))
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
      HStack {
        Image(systemName: contact.isCompany ? "building.2.crop.circle.fill" : "person.crop.circle.fill")
          .font(.system(size: 40))
          .foregroundStyle(.linearGradient(colors: [.gray.opacity(0.7), .gray.opacity(0.5)],
                                           startPoint: .bottom, endPoint: .top))
          
        
        VStack(alignment: .leading) {
          Text(verbatim: !contact.isCompany ? "\(contact.name)" : "\(contact.companyName)" )
            .lineLimit(1)
            .font(.headline)
          
          if !contact.isCompany {
            Text(verbatim: contact.companyName)
              .lineLimit(1)
              .font(.subheadline)
              .foregroundStyle(contact.isCompany ? .primary : .secondary)
              .lineLimit(1)
          }
        }
      }
    }
    .foregroundStyle(.primary)
  }
}

struct SavedContactTemplateList_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        SavedContactTemplateList()
          .environmentObject(InTransactDocument.mock())
      }
    }
}
