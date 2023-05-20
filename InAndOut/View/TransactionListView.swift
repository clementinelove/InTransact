//
//  TransactionListView.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-11.
//

import SwiftUI


enum TransactionSortKey {
  case total
  case date
}

import Combine
import DequeModule
import OrderedCollections


// MARK: - View
struct TransactionListView: View {
  
  class TransactionInspectorState: ObservableObject, Hashable {
    func hash(into hasher: inout Hasher) {
      hasher.combine(showInspector)
      hasher.combine(transactionIndex)
    }
    static func == (lhs: TransactionListView.TransactionInspectorState, rhs: TransactionListView.TransactionInspectorState) -> Bool {
      lhs.showInspector == rhs.showInspector && lhs.transactionIndex == rhs.transactionIndex
    }
    
    @Published var showInspector: Bool
    @Published var transactionIndex: Int
    
    init() {
      self.showInspector = false
      self.transactionIndex = 0
    }
    
    func inspect(index: Int) {
      Task { @MainActor in
        withAnimation(.easeOut) {
          // TODO: this animation looks ugly
          transactionIndex = index
        }
      }
      showInspector = true
    }
  }
  
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.undoManager) private var undoManager
  
  /// Presenting new transaction form in a sheet.
  @State private var isAddNewTransactionPresented: Bool = false
  
  /// The object that contains information on the states of transaction inspector.
  @StateObject private var transactionInspectorState = TransactionInspectorState()
  /// Tells whether user is currently editing a transaction in the transaction inspector sheet.
  @State private var isEditing = false
  /// Controls the inspector sheet detent
  @State private var transactionDetailDetent: PresentationDetent = .medium
  
  /// Presenting relevant statistics in a sheet.
  @State private var isPresentingItemStatisticsView = false
  @State private var itemNameFilter: String = ""
  @State private var variantNameFilter: String = ""
  
  /// Tells whether user is currently viewing document settings sheet.
  @State private var isPresentingDocumentSettings = false
  
  /// Tells whether user is currently viewing currency picker options.
  @State private var isShowingCurrencyPicker = false
  
  // TODO: build sort indexes
  @State var selectedSortKey: TransactionSortKey = .date
  @State var selectedSortOrder: SortOrder = .reverse
  
  @State var searchText: String = ""
  
  /// TODO: use states rather than dyanmic var to store transactions to avoid performance issues during deletion.
  var processedTransactions: [(offset: Int, element: Transaction)] {
    let filter: ((Int, Transaction) -> Bool) =
    !itemNameFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
    { (o, t) -> Bool in  t.itemNames.description.localizedCaseInsensitiveContains(itemNameFilter) } :
    { (o, t) -> Bool in true }
    
    return document.content.transactions.enumerated()
      .filter(filter)
      .sorted { e1, e2 in
      return sortComparator(e1.element, e2.element)
    }
  }
  
  var sortedTransactionIndexes: [Int] {
    processedTransactions
      .map { (originalOffset, transaction) in originalOffset }
  }
  
  var body: some View {
    Group {
      if document.content.transactions.isEmpty {
        EmptyListPlaceholder("No Transactions")
      } else {
        List {
          ForEach(sortedTransactionIndexes, id: \.self) { index in
            Button {
              // tap to inspect details
              
              transactionInspectorState.inspect(index: index)
              
            } label: {
              TransactionRowView(transaction: $document.content.transactions[index], currencyIdentifier: document.content.settings.currencyIdentifier)
            }
            //        .contextMenu {
            //          // copy, share, duplicate, delete
            //          Button {
            //            // FIXME: not implemented
            //          } label: {
            //            Label("Copy", systemImage: "doc.on.doc")
            //          }
            //
            //          Button {
            //            // FIXME: not implemented
            //          } label: {
            //            Label("Share", systemImage: "square.and.arrow.up")
            //          }
            //
            //          Button {
            //            // FIXME: not implemented
            //          } label: {
            //            Label("Duplicate", systemImage: "plus.square.on.square")
            //          }
            //
            //          Button(role: .destructive) {
            //            // FIXME: not implemented
            //          } label: {
            //            Label("Delete", systemImage: "plus.square.on.square")
            //          }
            //
            //        }
          }
          .onDelete { indexSet in
            let transactionsCache = processedTransactions
            let ids = indexSet.map { offset in
              transactionsCache[offset].element.id
            }
            document.deleteTransactions(withIDs: ids, undoManager: undoManager)
          }
          .listSectionSeparator(.hidden, edges: .top)
        }
      }
    }
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
    .listStyle(.plain)
    // MARK: List End without Overlay
    .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
      if !itemNameFilter.isEmpty {
        TransactionFilterBadge(filteredItemName: $itemNameFilter)
      }
    }
    // MARK: search bar
    .overlay { // Use .overlay to ensure the UI under is unchanged
      TransactionSearchResultView(searchText: $searchText,
                                  transactionInspectorState: transactionInspectorState,
                                  inspectorDetent: $transactionDetailDetent)
    }
    .searchable(text: $searchText, placement: .toolbar)
    // MARK: toolbar
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        
        newTransactionButton
          .padding(.bottom, 6)
        Spacer()
        Button {
          Task { @MainActor in
            await dismissAllSheets()
            isPresentingItemStatisticsView = true
          }
        } label: {
          Image(systemName: "chart.bar")
        }
        .padding(.bottom, 6)
      }
      
      ToolbarItemGroup(placement: .primaryAction) {
        
        Menu {
          Picker(selection: $selectedSortKey) {
            Label("Sort By Date", systemImage: "calendar")
              .tag(TransactionSortKey.date)
            Label("Sort By Total", systemImage: "dollarsign.circle")
              .tag(TransactionSortKey.total)
            
          } label: {
            // ..
          }.labelsHidden()
          
          Divider()
          
          // Sort Picker
          Picker(selection: $selectedSortOrder) {
            Text(selectedSortKey == .date ? "Latest First" : "Largest First")
              .tag(SortOrder.reverse)
            Text(selectedSortKey == .date ? "Earliest First": "Smallest First")
              .tag(SortOrder.forward)
            
          } label: { }.labelsHidden()
          
        } label: {
          Image(systemName: "arrow.up.arrow.down")
        }
        
        Menu {
          // TODO: Select Transactions (Edit Mode)..

          // TODO: share link
          // FIXME: document settings not implemented
//          Button("Document Settings") {
//            Task { @MainActor in
//              await dismissAllSheets()
//              isPresentingDocumentSettings = true
//            }
//          }
          
          Button {
            isShowingCurrencyPicker = true
          } label: {
            Label("Change Currency", systemImage: "banknote")
            Text(document.content.settings.currencyIdentifier)
          }

        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    // MARK: Item Statistics
    .sheet(isPresented: $isPresentingItemStatisticsView) {
      Task { @MainActor in
        isPresentingItemStatisticsView = false
      }
    } content: {
      NavigationStack {
        ItemListView(nameFilter: $itemNameFilter, variantNameFilter: $variantNameFilter)
          .toolbar {
            ToolbarItem(placement: .primaryAction) {
              Button("Done") {
                isPresentingItemStatisticsView = false
              }
            }
          }
          .toolbarRole(.navigationStack)
      }
    }
    // MARK: Document Settings
    .sheet(isPresented: $isPresentingDocumentSettings) {
      Task { @MainActor in
       isPresentingDocumentSettings = false
      }
    } content: {
      NavigationStack {
        DocumentSettingsView()
          .toolbarRole(.navigationStack)
      }
    }
    // MARK: Currency Picker
    .sheet(isPresented: $isShowingCurrencyPicker, onDismiss: {
      Task { @MainActor in
        await dismissAllSheets()
        isShowingCurrencyPicker = false
      }
    }) {
      NavigationStack {
        CurrencyPickerContent(currencyIdentifier: Binding(get: {
          document.content.settings.currencyIdentifier
        }, set: { newIdentifier in
          document.updateCurrency(newIdentifier, undoManager: undoManager)
        }))
        .navigationTitle("Update Document Currency")
        .toolbar(content: {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              isShowingCurrencyPicker = false
            }
          }
        })
          .toolbarRole(.navigationStack)
      }
    }
    // MARK: Transaction Detail Sheet
    .sheet(isPresented: $transactionInspectorState.showInspector, onDismiss: {
      isEditing = false
      transactionDetailDetent = .medium
      Task { @MainActor in
        transactionInspectorState.showInspector = false
      }
    }) {
      transactionDetailInspector
        .presentationDetents([.medium, .large], selection: $transactionDetailDetent)
        .presentationBackgroundInteraction(isEditing ? .disabled : .enabled(upThrough: .medium))
        .presentationContentInteraction(.scrolls)
    }
    // MARK: New Transaction Sheet
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
    // MARK: View End
  }

  @ViewBuilder
  var transactionDetailInspector: some View {
    NavigationStack {
      Group {
        // show empty content when index is less than transactions count - 1, otherwise it will cause out of bounds error
        let index = transactionInspectorState.transactionIndex
        if document.content.transactions.indices.contains(index) {
          if !isEditing {
            ScrollView(.vertical) {
              TransactionDetailView(transaction: $document.content.transactions[index]) {
                // ... on deletion is not needed here
              }
              .padding()
              
            }
            .scrollDismissesKeyboard(.immediately)
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
                  // dismiss sheet
                  Task { @MainActor in
                    transactionInspectorState.showInspector = false
                  }
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray, .gray.opacity(0.2))
                }
                .animationDisabled()
              }
            }
          } else {
            // During editing, transactionIndex can't be changed. otherwise it will cause serious problem
            TransactionEditView(edit: document.content.transactions[index]) { transaction in
              document.replaceTransactionContent(with: transaction, undoManager: undoManager)
            } onCompletion: {
              withAnimation {
                isEditing = false
              }
            }
          }
        } else {
          Text("No transaction is present")
            .foregroundStyle(.secondary)
            .task {
              // Immediately dismiss when no transaction presents
              withAnimation {
                transactionInspectorState.showInspector = false
                transactionDetailDetent = .medium
              }
            }
        }
      }
      .id(transactionInspectorState)
      .toolbarRole(.navigationStack)
    }
  }
  
  func dismissAllSheets() async {
    transactionInspectorState.showInspector = false
    isAddNewTransactionPresented = false
  }
  
  func deleteTransaction(_ transaction: Transaction) {
    guard let index = document.content.transactions.firstIndex(where: { $0 == transaction }) else { return }
    withAnimation {
      document.deleteTransaction(index: index, undoManager: undoManager)
    }
  }
  
  var newTransactionButton: some View {
    Button {
      Task { @MainActor in
        await dismissAllSheets()
        isAddNewTransactionPresented = true
      }
    } label: {
      Label("New Transaction", systemImage: "plus.circle")
        .fontDesign(.rounded)
        .fontWeight(.medium)
        .labelStyle(.titleAndIcon)
    }
  }
  
  // MARK: Sorting Related
  var sortComparator: ((Transaction, Transaction) -> Bool) {
    let roundingRules = document.content.settings.roundingRules
    switch selectedSortKey {
      case .total:
        switch selectedSortOrder {
          case .forward: //
            return { t1, t2 in
              let t1t = t1.total(roundingRules: roundingRules)
              let t2t = t2.total(roundingRules: roundingRules)
              if t1t != t2t {
                return t1t < t2t
              }
              if t1.date != t2.date {
                return t1.date < t2.date
              }
              if let t1k = t1.keeperName,
                 let t2k = t2.keeperName,
                 t1k != t2k {
                return t1k < t2k
              }
              if t1.transactionID != t2.transactionID {
                return t1.transactionID < t2.transactionID
              }
              // TODO: add other conditions when dates are equal
              return true
            }
          case .reverse:
            return { t1, t2 in
              let t1t = t1.total(roundingRules: roundingRules)
              let t2t = t2.total(roundingRules: roundingRules)
              if t1t != t2t {
                return t1t > t2t
              }
              if t1.date != t2.date {
                return t1.date < t2.date
              }
              if let t1k = t1.keeperName,
                 let t2k = t2.keeperName,
                 t1k != t2k {
                return t1k < t2k
              }
              if t1.transactionID != t2.transactionID {
                return t1.transactionID < t2.transactionID
              }
              // TODO: add other conditions when dates are equal
              return true
            }
        }
      case .date:
        switch selectedSortOrder {
          case .forward: // earliest first
            return { $0.date < $1.date } // TODO: add other conditions when dates are equal
          case .reverse: // latest first
            return { $0.date > $1.date } // TODO: add other conditions when dates are equal
        }
    }
  }
}

struct TransactionSearchResultView: View {
  
  @EnvironmentObject private var document: InAndOutDocument
  @Environment(\.isSearching) private var isSearching
  @Binding var searchText: String
  @ObservedObject var transactionInspectorState: TransactionListView.TransactionInspectorState
  @Binding var inspectorDetent: PresentationDetent
  
  var filteredTransactions: [Int] {
    let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return document.content.transactions.enumerated().filter { (i, t) in
      t.transactionID.localizedCaseInsensitiveContains(searchText) ||
      t.itemAndVariantNames.contains { $0.localizedCaseInsensitiveContains(trimmedSearchText) } ||
      t.date.formatted(date: .long, time: .complete).localizedCaseInsensitiveContains(trimmedSearchText) ||
      t.date.formatted(.relative(presentation: .named)).localizedCaseInsensitiveContains(trimmedSearchText) ||
      t.total(roundingRules: document.content.settings.roundingRules).formatted().contains(trimmedSearchText)
    }.map { $0.offset }
    // TODO: sort the result
  }
  
  var body: some View {
    Group {
      if isSearching && !searchText.isEmpty {
        List {
          ForEach(filteredTransactions, id: \.self) { i in
            Button {
              // tap to inspect details
              inspectorDetent = .large
              Task { @MainActor in
                withAnimation {
                  transactionInspectorState.inspect(index: i)
                }
              }
            } label: {
              TransactionRowView(transaction: $document.content.transactions[i],
                                 currencyIdentifier: document.content.settings.currencyIdentifier)
            }
          }
        }

        .scrollDismissesKeyboard(.interactively)
        .listStyle(.plain)
        #if os(iOS)
        .background(Color.system)
        #else
        .background { Color(nsColor: .controlBackgroundColor) }
        #endif
      }
    }
    .task(id: searchText) {
      print("Is searching: \(isSearching), Search Text: \(searchText)")
    }
    .task(id: isSearching) {
      withAnimation {
        transactionInspectorState.showInspector = false
      }
    }
  }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
      
      NavigationStack {
        TransactionListView()
          .environmentObject(InAndOutDocument(mock: false))
      }
      
      NavigationStack {
        TransactionListView()
          .environmentObject(InAndOutDocument(mock: true))
      }
      
      TransactionSearchResultView(searchText: .constant("3"), transactionInspectorState: .init(), inspectorDetent: .constant(.large))
        .environmentObject(InAndOutDocument(mock: true))
    }
}
