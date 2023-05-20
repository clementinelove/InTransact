//
//  TransactionDetailInspector.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-15.
//

import SwiftUI
import NTPlatformKit

struct TransactionDetailInspector: View {
  @Binding var transaction: Transaction
  @State private var isEditing = false
  @State private var transactionDetailDetent: PresentationDetent = .medium
    var body: some View {
      Rectangle()
        .sheet(isPresented: .constant(true)) {
        content
          .presentationDetents([.medium, .large], selection: $transactionDetailDetent)
          .presentationBackgroundInteraction(.enabled(upThrough: .medium))
          .presentationContentInteraction(.scrolls)
      }
    }
  
  @ViewBuilder
  var content: some View {
    NavigationStack {
      if !isEditing {
        ScrollView(.vertical) {
          TransactionDetailView(transaction: $transaction) {
            // ...
          }
          .padding()
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Edit") {
              withAnimation {
                isEditing = true
                transactionDetailDetent = .large
              }
            }
            .animationDisabled()
          }
          
          ToolbarItem(placement: .cancellationAction) {
            Button {
              // TODO: dismiss sheet
              
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray, .gray.opacity(0.2))
            }
            .animationDisabled()
          }
        }
      } else {
        TransactionEditView(edit: transaction) { transaction in
          self.transaction = transaction
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              withAnimation {
                isEditing = false
              }
            }
            .animationDisabled()
          }
          
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              withAnimation {
                isEditing = false
                transactionDetailDetent = .large
              }
            }
            .animationDisabled()
          }
        }
      }
    }
  }
}

struct TransactionDetailInspector_Previews: PreviewProvider {
    static var previews: some View {
      TransactionDetailInspector(transaction: .constant(.mock()))

      .environmentObject(InAndOutDocument.mock())
    }
}
