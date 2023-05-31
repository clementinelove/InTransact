//
//  ContactView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI

struct ContactView: View {
  
  let contact: Contact
  var hideDetailsByDefault: Bool = false
  
  @State private var showDetails: Bool = false
  
  var body: some View {
    if contact.isAllEmpty {
      Text("No Contact Info")
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical)
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
    } else {
      VStack(alignment: .leading, spacing: 10) {
        ZStack(alignment: .trailingLastTextBaseline) {
          VStack(alignment: .leading) {
            if !contact.isCompany && !contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              Text(verbatim: contact.name)
                .font(.headline)
                .multilineTextAlignment(.leading)
            }
            if let companyName = contact.companyName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Text(verbatim: companyName)
                .font(contact.isCompany ? .headline: .body)
                .multilineTextAlignment(.leading)
            }
            
            if let phoneNumber = contact.phoneNumber.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              if let phoneURL = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                Link(destination: phoneURL) {
                  Text(verbatim: phoneNumber)
                    .foregroundStyle(Color.accentColor)
                    .multilineTextAlignment(.leading)
                }
              } else {
                Text(verbatim: phoneNumber)
                  .foregroundColor(.secondary)
                  .multilineTextAlignment(.leading)
              }
            }
            
            if let email = contact.email.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              if let emailURL = URL(string: "mailto:\(email)") {
                Link(destination: emailURL) {
                  Text(verbatim: email)
                    .foregroundStyle(Color.accentColor)
                    .multilineTextAlignment(.leading)
                }
              } else {
                Text(verbatim: contact.email)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.leading)
                  
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .animationDisabled()
          
          if hideDetailsByDefault && !showDetails && contact.hasDetails {
            Button {
              withAnimation {
                showDetails = true
              }
            } label: {
              Text("Show Details", comment: "Expand details of a transaction counterparty")
                .multilineTextAlignment(.trailing)
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 10)
            .background {
              #if os(iOS)
              Color.system
                .blur(radius: 4)
              #else
              Color.textBackgroundColor
                .blur(radius: 4)
              #endif
            }
//            .border(.red)
            
          }
        }
        
        if !hideDetailsByDefault || showDetails {
          VStack(alignment: .leading) {
            if let taxID = contact.taxID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Text("Tax ID: \(taxID)")
                .multilineTextAlignment(.leading)
            }
            if let address = contact.address.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Text(verbatim: address)
                .multilineTextAlignment(.leading)
            }
            
            if let postalCode = contact.postalCode.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) {
              Text(verbatim: postalCode)
                .multilineTextAlignment(.leading)
            }
          }
          .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
          .onTapGesture {
            if hideDetailsByDefault {
              withAnimation {
                showDetails = false
              }
            }
          }
        }
      }
    }
  }
}

struct ContactView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      List {
        ContactView(contact: .mock())
        ContactView(contact: .fresh())
      }
      List {
        ContactView(contact: .mock())
        ContactView(contact: .fresh())
      }
      .listStyle(.plain)
    }
    
    VStack {
      List {
        ContactView(contact: .mock(), hideDetailsByDefault: true)
        ContactView(contact: .fresh(), hideDetailsByDefault: true)
      }
      List {
        ContactView(contact: .mock(), hideDetailsByDefault: true)
        ContactView(contact: .fresh(), hideDetailsByDefault: true)
      }
      .listStyle(.plain)
      VStack {
        ContactView(contact: .mock(), hideDetailsByDefault: true)
        ContactView(contact: .fresh(), hideDetailsByDefault: true)
      }
      .listStyle(.plain)
    }
    .previewDisplayName("Hide Details")
    
    
    List {
      ContactView(contact: Contact(isCompany: false, name: "", companyName: "猪王", email: "", phoneNumber: "", taxID: "", address: "", postalCode: "s", notes: ""), hideDetailsByDefault: false)
      ContactView(contact: .fresh(), hideDetailsByDefault: false)
    }
    .previewDisplayName("Hide Details (Scattered Info)")
  }
}
