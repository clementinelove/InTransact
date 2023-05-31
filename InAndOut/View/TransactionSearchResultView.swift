//
//  TransactionSearchResultView.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import SwiftUI

struct TransactionSearchResultView: View {
  
  @EnvironmentObject private var document: InTransactDocument
  @Environment(\.isSearching) private var isSearching
  @Binding var searchText: String
  @ObservedObject var transactionInspectorState: DocumentMainView.TransactionInspectorState
  @Binding var inspectorDetent: PresentationDetent
  
  var filteredTransactions: [Int] {
    let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return document.content.transactions.enumerated().filter { (i, t) in
      t.transactionID.localizedStandardContains(searchText) ||
      t.invoiceID.localizedStandardContains(searchText) ||
      counterpartyMatched(t) ||
      t.itemAndVariantNames.contains { $0.localizedStandardContains(trimmedSearchText) } ||
      (t.keeperName?.localizedStandardContains(trimmedSearchText) ?? false) ||
      t.date.formatted(date: .long, time: .complete).localizedStandardContains(trimmedSearchText) ||
      t.date.formatted(.relative(presentation: .named)).localizedStandardContains(trimmedSearchText) ||
      t.total(roundingRules: document.roundingRules).formatted().localizedStandardContains(trimmedSearchText)
    }.map { $0.offset }
    // TODO: sort the result
  }
  
  func counterpartyMatched(_ transaction: Transaction) -> Bool {
    guard let counterpartyContact = transaction.counterpartyContact else { return false }
    return counterpartyContact.textContains(searchText)
    
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
    //    .task(id: searchText) {
    //      logger.debug("Is searching: \(isSearching), Search Text: \(searchText)")
    //    }
    .task(id: isSearching) {
      withAnimation {
        transactionInspectorState.showInspector = false
      }
    }
  }
}

struct TransactionSearchResultView_Previews: PreviewProvider {
    static var previews: some View {
      VStack {
        TransactionSearchResultView(searchText: .constant(""), transactionInspectorState: .init(), inspectorDetent: .constant(.large))
          .environmentObject(InTransactDocument.mock())
          .previewDisplayName("Search Results")
      }
    }
}
