//
//  TransactionEditView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import NTPlatformKit

enum EditMode {
  case new
  case edit
}

class TransactionViewModel: ObservableObject {
  @Published var transactionType: TransactionType = .itemsIn
  @Published var transactionID: String = ""
  @Published var date: Date = Date.now
  @Published var keeperName: String = ""
  @Published var subtransactions: [ItemTransaction] = []
  @Published var comment: String = ""
  var isValid: Bool {
    !subtransactions.isEmpty
  }
  // TODO: addable verification
  
  var transaction: Transaction
  var editMode: EditMode
  
  init(edit transaction: Transaction) {
    self.transaction = transaction
    self.editMode = .edit
    
    self.transactionType = transaction.transactionType
    self.transactionID = transaction.transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.date = transaction.date
    self.keeperName = transaction.keeperName ?? ""
    self.subtransactions = transaction.subtransactions
    self.comment = transaction.comment
    commonInit()
  }
  
  init(new type: TransactionType, transactionID: String = "") {
    transaction = .fresh(type: type)
    transaction.transactionID = transactionID
    self.transactionType = transaction.transactionType
    self.transactionID = transaction.transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.date = transaction.date
    self.keeperName = transaction.keeperName ?? ""
    self.subtransactions = transaction.subtransactions
    self.comment = transaction.comment
    
    self.editMode = .new
    commonInit()
  }
  
  func commonInit() {
    // ... do nothing at the moment
  }
  
  func insert(subtransaction: ItemTransaction, at index: Int) {
    self.subtransactions.insert(subtransaction, at: index)
  }
  
  func append(subtransaction: ItemTransaction) {
    self.subtransactions.append(subtransaction)
  }
  
  var hasChanges: Bool {
    return
    self.transactionType != transaction.transactionType ||
    self.transactionID.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.transactionID ||
    self.date != transaction.date ||
    self.keeperName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) != transaction.keeperName?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ||
    self.subtransactions != transaction.subtransactions ||
    self.comment.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  
  
  var updatedTransaction: Transaction {
    Transaction(id: transaction.id,
                transactionType: transactionType,
                transactionID: transactionID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? UUID().uuidString, // generate random ID if empty
                subtransactions: subtransactions,
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                keeperName: keeperName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines),
                date: date)
  }
}

struct TransactionEditView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var document: InAndOutDocument
  @StateObject private var viewModel: TransactionViewModel
  @State private var editingItem: Binding<ItemTransaction>? = nil
  @State private var showAddItemTransactionView = false
  @State private var attemptToDiscardChanges: Bool = false
  private var onCommit: (Transaction) -> Void
  private var onCompletion: (() -> Void)? = nil
  private var dismissAfterCompletion: Bool
  init(edit transaction: Transaction, dismissAfterCompletion: Bool = false, onCommit: @escaping (Transaction) -> Void, onCompletion: (() -> Void)? = nil) {
    self._viewModel = StateObject(wrappedValue: TransactionViewModel(edit: transaction))
    self.dismissAfterCompletion = dismissAfterCompletion
    self.onCommit = onCommit
    self.onCompletion = onCompletion
  }
  
  init(new type: TransactionType, dismissAfterCompletion: Bool = true, onCommit: @escaping (Transaction) -> Void, onCompletion: (() -> Void)? = nil) {
    _viewModel = StateObject(wrappedValue: TransactionViewModel(new: type, transactionID: ""))
    self.dismissAfterCompletion = dismissAfterCompletion
    self.onCommit = onCommit
    self.onCompletion = onCompletion
  }
  
  var body: some View {
    Form {
      Section {
        Picker("Transaction Type", selection: $viewModel.transactionType) {
          Text("Items In")
            .tag(TransactionType.itemsIn)
          Text("Items Out")
            .tag(TransactionType.itemsOut)
        }
      } footer: {
        Text("Items In: records items moving in\nItems Out: records items moving out")
      }
      
      Section {
        HStack {
          TextField("Transaction ID", text: $viewModel.transactionID)
          Menu {
            // ...
            Button {
              viewModel.transactionID = UUID().uuidString
            } label: {
              Label("Generate Random ID", systemImage: "number.circle")
            }
          } label: {
            Image(systemName: "dice")
          }
        }
        TextField("Keeper Name", text: $viewModel.keeperName)
        // TODO: add contact picker for keeper info
        DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
      } footer: {
        Text("Every transaction needs be identified by a transaction ID. If you leave this field to be empty, \(Global.appName) will generate a random ID for you.")
      }
      
      /*
       Contact info of
      Section("Contact Info") {
        TextField("Name", text: .constant(""))
          .keyboardType(.namePhonePad)
        TextField("Phone Number", text: .constant(""))
          .keyboardType(.namePhonePad)
        TextField("Email", text: .constant(""))
          .keyboardType(.emailAddress)
        TextField("Address", text: .constant(""))
        TextField("Phone Number", text: .constant(""))
          .keyboardType(.namePhonePad)
      }
       */
      
      Section("Items") {
        
        ForEach($viewModel.subtransactions) { item in
          Button {
            editingItem = item
          } label: {
            ItemTransactionRow(itemTransaction: item)
          }
          .foregroundStyle(.primary)
          .draggable(item.wrappedValue) {
            ItemTransactionRow(itemTransaction: item)
              .padding()
              .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
        .onDelete { indexSet in
          viewModel.subtransactions.remove(atOffsets: indexSet)
        }
        .onMove { indexSet, destination in
          viewModel.subtransactions.move(fromOffsets: indexSet, toOffset: destination)
        }
        
        // TODO: quickly add from template
        //        Button {
        //
        //        } label: {
        //          Label("Add Item From Template", systemImage: "plus.square.on.square")
        //            .imageScale(.large)
        //        }
        
        Button {
          showAddItemTransactionView = true
        } label: {
          Label("Add Item", systemImage: "plus")
            .imageScale(.large)
        }
        
      }
      
      Section {
        TextField("Notes & Comments", text: $viewModel.comment, axis: .vertical)
          .frame(minHeight: 120, alignment: .top)
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .sheet(item: $editingItem, onDismiss: {
      Task {
        await MainActor.run {
          editingItem = nil
        }
      }
    }) { item in
      NavigationStack {
        ItemTransactionEditView(edit: item.wrappedValue) { resultItemTransaction in
          item.wrappedValue = resultItemTransaction
          // Don't save here
        }
          
          .toolbarRole(.navigationStack)
      }
    }
    // MARK: Add new item
    .sheet(isPresented: $showAddItemTransactionView, onDismiss: {
      Task {
        await MainActor.run {
          editingItem = nil
        }
      }
    }) {
      NavigationStack {
        ItemTransactionEditView { subtransaction in
          viewModel.append(subtransaction: subtransaction)
        }
        .toolbarRole(.navigationStack)
      }
    }
    // MARK: Toolbar
    .toolbar {
      
      ToolbarItem(placement: .confirmationAction) {
        confirmationButton
      }
      
      ToolbarItem(placement: .cancellationAction) {
        cancelButton
      }
      
    }
    .navigationTitle(title)
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
    .confirmationDialog("Do you wish to discard all changes?", isPresented: $attemptToDiscardChanges) {
      Button("Discard Changes", role: .destructive) {
        dismiss()
      }
    }
    .interactiveDismissDisabled(viewModel.hasChanges)
    // MARK: view end
  }
  
  var title: String {
    viewModel.editMode == .edit ? "Edit Transaction" : "New Transaction"
  }
  
  @ViewBuilder
  var confirmationButton: some View {
    Button(viewModel.editMode == .edit ? "Done" : "Add") {
      onCommit(viewModel.updatedTransaction)
      onCompletion?()
      if dismissAfterCompletion {
        dismiss()
      }
    }
    .disabled(!viewModel.isValid)
    .animationDisabled()
  }
  
  var cancelButton: some View {
    Button("Cancel") {
      if viewModel.hasChanges {
        attemptToDiscardChanges = true
      } else {
        onCompletion?()
        if dismissAfterCompletion {
          dismiss()
        }
      }
    }
    .animationDisabled()
  }
}

struct TransactionEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      TransactionEditView(edit: .mock()) { _ in }
        .environmentObject(InAndOutDocument.mock())
    }
    .previewDisplayName("Edit")
    
    NavigationStack {
      TransactionEditView(new: .itemsIn) { _ in
      }
      .environmentObject(InAndOutDocument.mock())
    }
    .previewDisplayName("New")
  }
}
