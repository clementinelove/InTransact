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
  
  var description: LocalizedStringKey {
    switch self {
      case .date: return "Date"
      case .total: return "Total"
    }
  }
}

import Combine
import DequeModule
import OrderedCollections


// MARK: - View
struct TransactionListView: View {
  
  private static let localizationTable = "TransactionList"
  
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
  
  @EnvironmentObject private var document: InTransactDocument
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
  
  @State private var isPresentingDocumentExporter = false
  
  /// Tells whether user is currently viewing currency picker options.
  @State private var isShowingCurrencyPicker = false
  
  // TODO: build sort indexes
  @State var selectedSortKey: TransactionSortKey = .date
  @State var selectedSortOrder: SortOrder = .reverse
  
  @State var searchText: String = ""
  var fileURL: URL? = nil
  
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
        #if os(iOS)
        
        transactionList
        #elseif os(macOS)
        NavigationSplitView {
          transactionList
          .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
        } detail: {
          ScrollView(.vertical) {
            TransactionDetailView(transaction: $document.content.transactions[transactionInspectorState.transactionIndex]) {
              // on delete
            }
            .padding()
          }
        }
        #endif
      }
    }

#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("")
    #endif
    
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
          #if os(iOS)
          .toolbarRole(.navigationStack)
          #endif
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
          #if os(iOS)
          .toolbarRole(.navigationStack)
          #endif
      }
    }
    // MARK: Document Exporter
    .sheet(isPresented: $isPresentingDocumentExporter) {
      Task { @MainActor in
        isPresentingDocumentExporter = false
      }
    } content: {
      NavigationStack {
        DocumentExportView(title: documentName, document: document)
#if os(iOS)
          .toolbarRole(.navigationStack)
#endif
      }
    }
    // MARK: Currency Picker
    .sheet(isPresented: $isShowingCurrencyPicker, onDismiss: {
      Task { @MainActor in
        isShowingCurrencyPicker = false
      }
    }) {
      NavigationStack {
        CurrencyPickerContent(currencyIdentifier: Binding(get: {
          document.currencyCode
        }, set: { newIdentifier in
          document.updateCurrency(newIdentifier, undoManager: undoManager)
        }))
        .navigationTitle(Text("Update Document Currency", comment: "Navigation title of view that changes current document currency"))
        .toolbar(content: {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              isShowingCurrencyPicker = false
            }
          }
        })
#if os(iOS)
        .toolbarRole(.navigationStack)
#endif
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
        #if os(iOS)
.toolbarRole(.navigationStack)
#endif
      }
    }
    // MARK: List Toolbar
    .toolbar {
      #if os(iOS)
      ToolbarItemGroup(placement: .bottomBar) {
        newTransactionButton
          .padding(.bottom, 6)
        Spacer()
        itemCountButton
          .padding(.bottom, 6)
      }
      #else
      ToolbarItemGroup(placement: .primaryAction) {
        newTransactionButton
        Spacer()
        itemCountButton
      }
      #endif
      
      ToolbarItemGroup(placement: .primaryAction) {
        sortMethodMenu
      }
      
      // MARK: Ellipsis Menu
      ToolbarItemGroup(placement: .secondaryAction) {
        
        // Very unstable
//        if let fileURL {
//          ShareLink(item: fileURL)
//        }
        
        Button {
          Task { @MainActor in
            try await dismissInspectorSheet()
            isPresentingDocumentExporter = true
          }
        } label: {
          Label {
            Text("Export To CSV", comment: "Button title that exports the document in the csv format")
          } icon: {
            Image(systemName: "tablecells")
          }
        }
        
        Button {
          
          Task { @MainActor in
            try await dismissInspectorSheet()
            isShowingCurrencyPicker = true
          }
        } label: {
          
          Label {
            Text("Change Currency", comment: "Button title that taps to change the current document currency")
          } icon: {
            Image(systemName: "banknote")
          }
          
          Text(verbatim: document.currencyCode)
        }
      }
    }
    // MARK: View End
  }
  
//  var searchable: some View {
//    // MARK: List End without Overlay
//    .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
//      if !itemNameFilter.isEmpty {
//        TransactionFilterBadge(filteredItemName: $itemNameFilter)
//      }
//    }
//    // MARK: search bar
//    .overlay { // Use .overlay to ensure the UI under is unchanged
//      TransactionSearchResultView(searchText: $searchText,
//                                  transactionInspectorState: transactionInspectorState,
//                                  inspectorDetent: $transactionDetailDetent)
//    }
//
//    // Searchable modifier should always put after the search results overlay
//#if os(iOS)
//    .searchable(text: $searchText, placement: .toolbar)
//#elseif os(macOS)
//    .searchable(text: $searchText, placement: .sidebar)
//#endif
//  }
  
  var transactionList: some View {
    #if os(iOS)
    List {
      ForEach(sortedTransactionIndexes, id: \.self) { index in
        Button {
          // tap to inspect details
          transactionInspectorState.inspect(index: index)
        } label: {
          TransactionRowView(transaction: document.content.transactions[index], currencyIdentifier: document.currencyCode)
        }
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
    .listStyle(.plain)
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
    
    // Searchable modifier should always put after the search results overlay
    .searchable(text: $searchText, placement: .toolbar)
    #elseif os(macOS)
      List(selection: $transactionInspectorState.transactionIndex) {
        ForEach(sortedTransactionIndexes, id: \.self) { index in
          
          TransactionRowView(transaction: document.content.transactions[index], currencyIdentifier: document.currencyCode)
            .padding(.vertical, 4)
            .listRowSeparator(.visible, edges: .bottom)
            .tag(index)
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
      
      .listStyle(.sidebar)
    #endif
  }

  // MARK: Item Count Sheet Button
  var itemCountButton: some View {
    // Shouldn't use a button here because button can still be triggered when a menu is presented, which cause very serious bugs in SwiftUI
    Menu {
      
    } label: {
      Image(systemName: "chart.bar")
    } primaryAction: {
      Task { @MainActor in
        try await dismissInspectorSheet()
        isPresentingItemStatisticsView = true
      }
    }
  }
  
  // MARK: Sort Menu
  var sortMethodMenu: some View {
    Menu {
      Picker(selection: $selectedSortKey) {
        Label {
          Text("Sort By Date", comment: "Button title to sort transactions by date")
        } icon: {
          Image(systemName: "calendar")
        }
        .tag(TransactionSortKey.date)
        Label {
          Text("Sort By Total", comment: "Button title to sort transactions by transaction total")
        } icon: {
          Image(systemName: "calendar")
        }
        .tag(TransactionSortKey.total)
      } label: {
        // ..
      }.labelsHidden()
      
      Divider()
      // Sort Picker
      Picker(selection: $selectedSortOrder) {
        if selectedSortKey == .date
        {
          Text("Latest First", comment: "Button title that sort transactions by latest date first")
            .tag(SortOrder.reverse)
          Text("Earliest First", comment: "Button title that sort transactions by earliest date first")
            .tag(SortOrder.forward)
        } else {
          Text("Largest First", comment: "Button title that sort transactions by largest total first")
            .tag(SortOrder.reverse)
          Text("Smallest First", comment: "Button title that sort transactions by smallest total first")
            .tag(SortOrder.forward)
        }
      } label: { }.labelsHidden()
      
    } label: {
        Label {
          Text("Sort Method", comment: "Button title that selects sort method and sort order")
            
          + Text(verbatim: " – ") + Text(selectedSortKey.description)
        } icon: {
          Image(systemName: "arrow.up.arrow.down")
        }
        .labelStyle(.iconOnly)
    }
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
          Text("No Transaction Selected")
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
      #if os(iOS)
.toolbarRole(.navigationStack)
#endif
    }
  }
  
  /**
   Dismiss inspector sheet. Call this whenever you need to show information in a sheet when the inspector sheet may in presentation.
   Because SwiftUI only allows presenting one sheet at a time, and the Inspector sheet may already be presenting when user tries to
   */
  func dismissInspectorSheet() async throws {
    transactionInspectorState.showInspector = false
    
    // Add delay to allow it fully dismiss otherwise there will be animation bug the SwiftUI will assume it hasn't dismiss cause other mess.
    try await Task.sleep(nanoseconds: 100000)
  }
  
  func deleteTransaction(_ transaction: Transaction) {
    guard let index = document.content.transactions.firstIndex(where: { $0 == transaction }) else { return }
    withAnimation {
      document.deleteTransaction(index: index, undoManager: undoManager)
    }
  }
  
  var newTransactionButton: some View {
    // Shouldn't use a button here because button can still be triggered when a menu is presented, which cause very serious bugs in SwiftUI
    Menu {
      // ...
    } label: {
      Label {
        Text("New Transaction", comment: "Button title that adds a new transaction")
          .fontDesign(.rounded)
      } icon: {
        Image(systemName: "plus.circle")
      }
      .labelStyle(.titleAndIcon)
      .fontWeight(.medium)
    } primaryAction: {
      Task { @MainActor in
        try await dismissInspectorSheet()
        isAddNewTransactionPresented = true
      }
    }
  }
  
  // MARK: Sorting Related
  var sortComparator: ((Transaction, Transaction) -> Bool) {
    let roundingRules = document.roundingRules
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
  
  var documentName: String? {
    guard let fileURL, let percentDecodedFileName = fileURL.lastPathComponent.removingPercentEncoding else {
      return nil
    }
    let seperatedFileName = percentDecodedFileName.split(separator: ".", maxSplits: Int.max)
    // Remove file extension then addback dots again
    let newFileName = seperatedFileName.dropLast(1).joined(separator: ".")
    return newFileName
  }
}

struct TransactionSearchResultView: View {
  
  @EnvironmentObject private var document: InTransactDocument
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
      t.total(roundingRules: document.roundingRules).formatted().contains(trimmedSearchText)
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
              TransactionRowView(transaction: document.content.transactions[i],
                                 currencyIdentifier: document.currencyCode)
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
          .environmentObject(InTransactDocument(mock: false))
      }
      .previewDisplayName("No Data (iOS)")
      
      NavigationStack {
        TransactionListView()
          .environmentObject(InTransactDocument(mock: true))
      }
      .previewDisplayName("With Mock Data (iOS)")
      
      TransactionListView()
        .environmentObject(InTransactDocument(mock: true))
        .previewDisplayName("With Mock Data (macOS)")
      
      
      TransactionSearchResultView(searchText: .constant("3"), transactionInspectorState: .init(), inspectorDetent: .constant(.large))
        .environmentObject(InTransactDocument(mock: true))
        .previewDisplayName("Search Results")
    }
}
