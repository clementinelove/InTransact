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
  @Published var fixedCosts: [FixedAmountItem] = []
  @Published var comment: String = ""
  
  var isValid: Bool {
    !subtransactions.isEmpty
  }
  // TODO: addable verification
  
  private var transaction: Transaction
  var editMode: EditMode
  
  init(edit transaction: Transaction) {
    self.transaction = transaction
    self.editMode = .edit
    
    self.transactionType = transaction.transactionType
    self.transactionID = transaction.transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.date = transaction.date
    self.keeperName = transaction.keeperName ?? ""
    self.subtransactions = transaction.subtransactions
    self.fixedCosts = transaction.fixedCosts
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
    self.fixedCosts = transaction.fixedCosts
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
    return self.transactionType != transaction.transactionType ||
    self.transactionID.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.transactionID ||
    self.date != transaction.date ||
    self.keeperName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) != transaction.keeperName?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ||
    self.subtransactions != transaction.subtransactions ||
    self.fixedCosts != transaction.fixedCosts ||
    self.comment.trimmingCharacters(in: .whitespacesAndNewlines) != transaction.comment.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  
  
  var updatedTransaction: Transaction {
    Transaction(id: transaction.id,
                transactionType: transactionType,
                transactionID: transactionID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ?? UUID().uuidString, // generate random ID if empty
                subtransactions: subtransactions,
                // Remove redundant items
                fixedCosts: fixedCosts.filter { item in
      !item.amount.isZero || !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    },
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                keeperName: keeperName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines),
                date: date)
  }
}

// MARK: - View
struct TransactionEditView: View {
  
  enum Field: Hashable {
    case keeperName
    case fixedCost(_ id: FixedAmountItem.ID)
    case notes
  }
  
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var document: InTransactDocument
  @StateObject private var viewModel: TransactionViewModel
  @State private var editingItem: Binding<ItemTransaction>? = nil
  @State private var showAddItemTransactionView = false
  @State private var attemptToDiscardChanges: Bool = false
  @FocusState private var focusField: Field?
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
        Text("Items In: records items moving in\nItems Out: records items moving out", comment: "Footer text that explains the meaning of each transaction type")
      }
      
      Section {
        HStack {
          TextField("Transaction ID", text: $viewModel.transactionID)
          Menu {
            // ...
            Button {
              viewModel.transactionID = UUID().uuidString
            } label: {
              Label {
                Text("Generate Random ID", comment: "Button title to generate random ID for transaction")
              } icon: {
                Image(systemName: "number.circle")
              }
            }
          } label: {
            Image(systemName: "dice")
          }
        }
        
        TextField("Keeper Name", text: $viewModel.keeperName)
          .focused($focusField, equals: .keeperName)
        // TODO: add contact picker for keeper info
        DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
      } footer: {
        Text("Every transaction needs be identified by a transaction ID. A random ID will be generated for you if you leave this field to be empty.", comment: "Footer text that explains a random ID is needed for every transaction and a random ID will be generated for user if they leave this field to be empty")
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
      
      Section {
        
        ForEach($viewModel.subtransactions) { item in
          Button {
            editingItem = item
          } label: {
            ItemTransactionRow(itemTransaction: item, showTaxDetails: true)
          }
          .foregroundStyle(.primary)
//          .draggable(item.wrappedValue) {
//            ItemTransactionRow(itemTransaction: item)
//              .padding()
//              .clipShape(RoundedRectangle(cornerRadius: 10))
//          }
        }
        .onDelete { indexSet in
          viewModel.subtransactions.remove(atOffsets: indexSet)
        }
        .onMove { indexSet, destination in
          viewModel.subtransactions.move(fromOffsets: indexSet, toOffset: destination)
        }
        
        Button {
          showAddItemTransactionView = true
        } label: {
          Label {
            Text("Add Item", comment: "Button title that adds a new item to a transaction")
          } icon: {
            AddNewItemImage()
          }
        }
        
      } header: {
        Text("Items", comment: "Section title, in which lists items that contained in a transaction")
      }
      
      Section {
        fixedCostItems()
      } header: {
        Text("Other Costs", comment: "Section title of other fixed costs in a transaction")
      }
      
      Section {
        TextField("Notes & Comments", text: $viewModel.comment, axis: .vertical)
          .focused($focusField, equals: .notes)
          .frame(minHeight: 120, alignment: .top)
      }
    }
    .scrollDismissesKeyboard(.interactively)
    // MARK: Edit new item
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
          #if os(iOS)
        .toolbarRole(.navigationStack)
#endif
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
        #if os(iOS)
        .toolbarRole(.navigationStack)
        #endif
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
  
  var title: LocalizedStringKey {
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
  
  func fixedCostItems() -> some View {
    Group {
      ForEach($viewModel.fixedCosts) { $item in
        VStack(alignment: .leading) {
          HStack {
            TextField("Cost Name", text: $item.name)
            CurrencyTextField(amount: $item.amount,
                              focusedBinding: $focusField,
                              value: .fixedCost($item.wrappedValue.id),
                              alignment: .trailing)
            .labelsHidden()
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
          }
        }
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
      }
      .onDelete { indexSet in
        viewModel.fixedCosts.remove(atOffsets: indexSet)
      }
      
      Button {
        withAnimation {
          viewModel.fixedCosts.append(FixedAmountItem.fresh())
        }
      } label: {
        Label {
          Text("Add New Fixed Cost", comment: "Button to add a new fixed cost item to a transaction")
        } icon: {
          AddNewItemImage()
        }
      }
      .alignmentGuide(.listRowSeparatorLeading) {
        $0[.leading]
      }
    }
  }
  
}

struct TransactionEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      TransactionEditView(edit: .mock()) { _ in }
        .environmentObject(InTransactDocument.mock())
    }
    .previewDisplayName("Edit")
    
    NavigationStack {
      TransactionEditView(new: .itemsIn) { _ in
      }
      .environmentObject(InTransactDocument.mock())
    }
    .previewDisplayName("New")
  }
}
