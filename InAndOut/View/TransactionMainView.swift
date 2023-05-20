//
//  TransactionMainView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-14.
//

import SwiftUI

struct TransactionMainView: View {
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.undoManager) var undoManager
  @State private var isAddNewTransactionPresented = false
  var body: some View {
    VStack(spacing: 0) {
      ScrollView(.vertical) {
        LazyVStack {
          ForEach($document.content.transactions.indices, id: \.self) { id in
            TransactionDetailView(transaction: $document.content.transactions[id]) {
            }
            .id(id)
            Text("*  *  *")
              .font(.system(size: 24).bold())
              .fontDesign(.serif)
              .monospaced()
              .padding(.vertical)
              .foregroundColor(.primary)
          }
        }
        .padding()
      }
    }
    .toolbar {
      // MARK: Toolbar
      ToolbarItemGroup(placement: .primaryAction) {
        newTransactionButton
      }
    }
    .sheet(isPresented: .constant(true), content: {
      VStack(alignment: .leading, spacing: 0) {
        Text("Transactions")
          .font(.headline)
          .padding()
        transactionsThumbnailView
      }
      .presentationDetents([.height(270), .large])
      .presentationBackgroundInteraction(.enabled(upThrough: .height(270)))
      .presentationDragIndicator(.hidden)
    })
    .sheet(isPresented: $isAddNewTransactionPresented) {
      Task { @MainActor in
        isAddNewTransactionPresented = false
      }
    } content: {
      NavigationStack {
        TransactionEditView(new: .itemsIn) { transaction in
          withAnimation {
            document.addNewTransaction(transaction, undoManager: undoManager)
          }
        }
        .toolbarRole(.navigationStack)
      }
    }
  }
  
  
  var transactionsThumbnailView: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 10) {
        ForEach($document.content.transactions.indices, id: \.self) { id in
          VStack {
            TransactionDetailView(transaction: $document.content.transactions[id]) {
            }
            .frame(width: 400)
            .scaleEffect(0.2, anchor: .top)
            .fixedSize(horizontal: true, vertical: false)
            .frame(width: 100, height: 100, alignment: .top)
            .padding(.horizontal, 6)
            .padding(.vertical, 12)
            .clipped()
            .overlay {
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(lineWidth: 3, antialiased: true)
                .foregroundColor(.accentColor)
            }
            let t = document.content.transactions[id]
            Text(t.date.formatted(date: .abbreviated, time: .omitted))
              .lineLimit(1)
              .font(.system(size: 13))
              .fontWeight(.medium)
            Text(t.date.formatted(date: .omitted, time: .shortened))
              .lineLimit(1)
              .font(.system(size: 17).bold())
              .fontDesign(.rounded)
          }
          .fixedSize()
          //            .border(.red)
        }
      }
      .padding(.horizontal)
      .padding(.top, 6)
      .padding(.bottom, 16)
    }
    .frame(height: 200)
  }
  var newTransactionButton: some View {
    Button {
      isAddNewTransactionPresented = true
    } label: {
      Label("Add New Transaction", systemImage: "plus")
        .labelStyle(.iconOnly)
    }
  }
}

struct TransactionMainView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      TransactionMainView()
    }
    .environmentObject(InAndOutDocument.mock())
    
  }
}
