//
//  NewTransactionFormView.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-07.
//

import SwiftUI
import Combine

import NTPlatformKit

// TODO: make toggles animatable

// MARK: - View Model
class ItemTransactionViewModel: ObservableObject {
  
  @Published var itemID: String = ""
  @Published var itemName: String = ""
  @Published var variantName: String = ""
  
  @Published var quantityText: String = "0"
  
  @Published var priceInfo: PriceInfo = PriceInfo(price: 0, priceType: .perUnitBeforeTax, explicitAfterTaxTotal: nil, quantity: 0)
  
  @Published var hasExplicitAfterTaxTotal = false
  @Published var explicitAfterTaxTotal: Decimal = Decimal(floatLiteral: 0.0)
  
  @Published var saveAsItemTemplate = false
  
  @Published var isValid: Bool = false
  
  private var cancellables = Set<AnyCancellable>()
  fileprivate var transaction: ItemTransaction

  init(edit transaction: ItemTransaction) {
    self.transaction = transaction
    
    // Copy data from transaction to viwe model
    self.itemID = transaction.itemID ?? ""
    self.itemName = transaction.itemName
    self.variantName = transaction.variant ?? ""
    self.quantityText = "\(transaction.priceInfo.quantity)"
    
    let priceInfo = self.transaction.priceInfo
      // TODO: assign priceInfo
      self.priceInfo = priceInfo
      
      if let explicitAfterTaxTotal = priceInfo.explicitAfterTaxTotal {
        if priceInfo.priceType == .perUnitBeforeTax || priceInfo.priceType == .sumBeforeTax {
          self.hasExplicitAfterTaxTotal = true
        }
        self.explicitAfterTaxTotal = explicitAfterTaxTotal
      }
    commonInit()
  }
  
  func commonInit() {
    $quantityText
      .removeDuplicates()
      .map { text in
        ItemQuantity(text, radix: 10)
      }
      .replaceNil(with: 0)
      .assign(to: \.priceInfo.quantity, on: self)
      .store(in: &cancellables)
    
    $priceInfo
      .map(\.quantity)
      .map {
        String($0)
      }
      .assign(to: \.quantityText, on: self)
      .store(in: &cancellables)
    
    Publishers
      .CombineLatest($hasExplicitAfterTaxTotal, $explicitAfterTaxTotal)
      .map {
        $0 ? $1 : nil
      }
      .assign(to: \.priceInfo.explicitAfterTaxTotal, on: self)
      .store(in: &cancellables)
    
    isFormValidPublisher
      .receive(on: RunLoop.main)
      .assign(to: \.isValid, on: self)
      .store(in: &cancellables)
  }
  
  func applyTemplate(_ template: ItemTemplate) {
    itemID = template.itemID ?? ""
    itemName = template.itemName
    variantName = template.variantName
    priceInfo = template.priceInfo
  }
  
  // MARK: Validity Publishers
  
  private var isItemNameValidPublisher: AnyPublisher<Bool, Never> {
    $itemName
      .removeDuplicates()
      .map { itemName in
        return itemName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
      }
      .eraseToAnyPublisher()
  }
  
  private var isQuantityValidPublisher: AnyPublisher<Bool, Never> {
    $priceInfo
      .map(\.quantity)
      .removeDuplicates()
      .map {
        $0 > 0
      }
      .eraseToAnyPublisher()
  }
  
  private var isFormValidPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest(isItemNameValidPublisher, isQuantityValidPublisher)
      .map { itemNameValid, quantityValid in
        return itemNameValid && quantityValid
      }
      .eraseToAnyPublisher()
  }
  
  var hasChanges: Bool {
    return self.itemID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) != self.transaction.itemID?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ||
    self.itemName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines) != self.transaction.itemName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines) ||
    self.variantName.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) != self.transaction.variant?.nilIfEmpty(afterTrimming: .whitespacesAndNewlines) ||
    self.priceInfo != self.transaction.priceInfo
  }
  
  var updatedItemTransaction: ItemTransaction {
    ItemTransaction(id: transaction.id,
                    itemID: itemID.nilIfEmpty(afterTrimming: .whitespacesAndNewlines),
                    itemName: itemName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines),
                    variant: variantName.emptyStringIfEmpty(afterTrimming: .whitespacesAndNewlines),
                    priceInfo: priceInfo.compacted)
  }
}
// MARK: - View
struct ItemTransactionEditView: View {
  
  enum Field: Hashable {
    case itemID
    case itemName
    case variantName
    case quantity
    case price
    case taxRate(_ id: RateTaxItem.ID)
    case fixedCost(_ id: FixedAmountItem.ID)
    case explicitTotalAfterTax
  }

  @Environment(\.dismiss) private var dismiss

  @StateObject private var viewModel: ItemTransactionViewModel
  @FocusState private var focusField: Field?
  @State private var lastValidQuantity: ItemQuantity = 0
  @State private var attemptToDiscardChanges = false
  @State private var isShowingTemplates = false
  @EnvironmentObject private var document: InTransactDocument
  @State private var isShowingRepeatedTaxItemNameAlert = false
  private let editMode: FormEditMode
  private let onCommit: ((ItemTransaction, _ saveAsTemplate: Bool) -> Void) // Bool = saveAsTemplate
  
  init(edit item: ItemTransaction, onCommit: @escaping (ItemTransaction, _ saveAsTemplate: Bool) -> Void) {
    self.editMode = .edit
    self._viewModel = StateObject(wrappedValue: ItemTransactionViewModel(edit: item))
    self.onCommit = onCommit
  }
  
  init(onSave: @escaping (ItemTransaction, _ saveAsTemplate: Bool) -> Void) {
    self.editMode = .new
    self._viewModel = StateObject(wrappedValue: ItemTransactionViewModel(edit: ItemTransaction.fresh()))
    self.onCommit = onSave
  }
  
  var body: some View {
    Form {
      
      if document.content.itemTemplates.count > 0 {
        Section {
          Button {
            isShowingTemplates = true
          } label: {
            Label("Copy Info from Item Template", systemImage: "plus.square.on.square")
          }
        }
      }
      
      Section {
        TextField("Item ID", text: $viewModel.itemID)
          .focused($focusField, equals: .itemID)
        
        HStack {
          TextField("Item Name", text: $viewModel.itemName)
            .focused($focusField, equals: .itemName)
        }
        
        TextField("Variant Name", text: $viewModel.variantName)
          .focused($focusField, equals: .variantName)
        
      } footer: {
        Text("A variant name can be used to refer to a different version or option of an item.")
      }
      
      Section {
        
        // MARK: Price Type
        Picker(selection: $viewModel.priceInfo.priceType) {
          Text("Unit Price, Before Tax")
            .tag(PriceType.perUnitBeforeTax)
          Text("Unit Price, After Tax")
            .tag(PriceType.perUnitAfterTax)
          Text("Sum, Before Tax")
            .tag(PriceType.sumBeforeTax)
          Text("Sum, After Tax")
            .tag(PriceType.sumAfterTax)
          
        } label: {
          Text("Price Type")
        }
        
        // MARK: Price
        VerticalField {
          CurrencyTextField(amount: $viewModel.priceInfo.price,
                            focusedBinding: $focusField, value: .price,
                            alignment: .leading)
          .labelsHidden()
#if os(iOS)
          .keyboardType(.decimalPad)
#endif
          .multilineTextAlignment(.trailing)
        } label: {
          Text("\(priceLabel) (\(document.currencyCode))", comment: "PriceTypeLabel[space]CurrencyCode")
        }
        
        quantityInputControl
      }
      
      // MARK: Tax Rates

        Section {
          regularTaxItems
          compoundTaxItems
          fixedTaxItems
          
        } header: {
          Text("Tax Info")
        } footer: {
          Text("A regular tax is calculated based on its price before tax; a compound tax is calculated after all regular tax were applied.", comment: "Explains the meaning of regular tax and compound tax")
          // TODO: show examples in a sheet
        }
      
      // MARK: Explicit Price after tax section
      if viewModel.priceInfo.priceType == .perUnitBeforeTax ||
          viewModel.priceInfo.priceType == .sumBeforeTax {
        Section {
          Toggle(isOn: $viewModel.hasExplicitAfterTaxTotal.animated) {
            Text("Explicit After Tax Total", comment: "Toggle title that switches explicit after tax total input")
          }
          if viewModel.hasExplicitAfterTaxTotal {
            VerticalField {
              CurrencyTextField(amount: $viewModel.explicitAfterTaxTotal,
                                focusedBinding: $focusField,
                                value: Field.explicitTotalAfterTax,
                                alignment: .leading)
                  .labelsHidden()
#if os(iOS)
                  .keyboardType(.decimalPad)
#endif
                  .multilineTextAlignment(.trailing)
              
            } label: {
              Text("After Tax Total (\(document.currencyCode))", comment: "Label of after tax total text field")
            }
          }
        } footer: {
          Text("You can explicitly specifiy the after-tax total for this entry, it will be used to calculate the total of the whole transaction directly.", comment: "Section footer text that explains the use of explicit after tax total")
        }
      }
      
      
      Section {
        Toggle("Save Item Info as Template", isOn: $viewModel.saveAsItemTemplate)
      } footer: {
        Text("Save these information as template when the transaction is saved. This will override exising template for the same item name and variant.", comment: "Section footer text that explains the use when user choose to save item information they entered in a form as a template")
      }
      
    }
    // MARK: Form End
    .formStyle(.grouped)
    .scrollDismissesKeyboard(.interactively)
    .sheet(isPresented: $isShowingTemplates) {
      Task {
        await MainActor.run {
          isShowingTemplates = false
        }
      }
    } content: {
      NavigationStack {
        ItemTemplateListView(asSheet: true) { template in
          withAnimation {
            viewModel.applyTemplate(template)
          }
        }
        #if os(iOS)
.toolbarRole(.navigationStack)
#endif
      }
    }
    .alert("Tax Items Cannot Share the Same Name", isPresented: $isShowingRepeatedTaxItemNameAlert) {
      
    } message: {
      Text("Please rename repeated tax items.")
    }
    
    .navigationTitle(title)
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        confirmationButton
      }
      
      ToolbarItem(placement: .cancellationAction) {
        cancelButton
      }
    }
    .confirmationDialog("Do you wish to discard all changes?", isPresented: $attemptToDiscardChanges) {
      Button("Discard Changes", role: .destructive) {
        dismiss()
      }
    }
    .interactiveDismissDisabled(viewModel.hasChanges)
    
    // MARK: View End
  }
  
  var title: String {
    editMode == .edit ? String(localized: "Edit Item") : String(localized: "New Item")
  }
  
  var quantityInputControl: some View {
    VerticalField {
      TextField("", text: $viewModel.quantityText)
        .multilineTextAlignment(.leading)
#if os(iOS)
        .keyboardType(.numberPad)
        .submitLabel(.done)
#endif
        .lineLimit(1)
        .truncationMode(.tail)
        .focused($focusField, equals: .quantity)
        .onChange(of: viewModel.quantityText, perform: { newValue in
          if newValue == "" {
            viewModel.quantityText = "0"
          } else {
            let quantity = ItemQuantity(newValue) ?? lastValidQuantity
            lastValidQuantity = quantity
            viewModel.quantityText = "\(quantity)"
          }
        })
        .toolbar {
          ToolbarItemGroup(placement: .keyboard) {
            if focusField == .quantity {
              quickQuantityButtons
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(6)
                .padding(.top, 6)
            }
          }
        }
    } label: {
      Text("Quantity", comment: "Label that specifies quantity of a item in a transaction")
    }
  }
  
  var priceLabel: String {
    switch viewModel.priceInfo.priceType {
      case .perUnitBeforeTax:
        return String(localized: "Unit Price Before Tax")
      case .perUnitAfterTax:
        return String(localized: "Unit Price After Tax")
      case .sumBeforeTax:
        return String(localized: "Sum Before Tax")
      case .sumAfterTax:
        return String(localized: "Sum After Tax")
    }
  }
  
  var quickQuantityButtons: some View {
//    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 20) {
        
//        Button {
//          // TODO: implement undo
//        } label: {
//          Image(systemName: "arrow.uturn.backward")
//        }
        Button("0", role: .destructive) {
          viewModel.priceInfo.quantity = 0
        }
        
        Button("+1") {
          viewModel.priceInfo.quantity = viewModel.priceInfo.quantity + 1
        }
        
        Button("+10") {
          viewModel.priceInfo.quantity = viewModel.priceInfo.quantity + 10
        }
        
        Button("+100") {
          viewModel.priceInfo.quantity = viewModel.priceInfo.quantity + 100
        }
        
        
        Button("+1000") {
          viewModel.priceInfo.quantity = viewModel.priceInfo.quantity + 1000
        }
        
        Button("+10000") {
          viewModel.priceInfo.quantity = viewModel.priceInfo.quantity + 10000
        }
        

      }
      .padding(.bottom, 6)
      .font(.system(size: 17).bold())
      .buttonStyle(.borderless)
#if os(iOS)
      .buttonBorderShape(.capsule)
#endif
//    }
  }
    
  var regularTaxItems: some View {
    Group {
      ForEach($viewModel.priceInfo.regularTaxItems) { item in
        VerticalField("Regular Tax") {
          HStack {
            TextField("Tax Name", text: item.name)
            TextField("", value: item.rate, format: .percent.sign(strategy: .never))
              .labelsHidden()
              .multilineTextAlignment(.trailing)
              .focused($focusField, equals: .taxRate(item.id))
#if os(iOS)
              .keyboardType(.decimalPad)
#endif
          }
        }
        .onSubmit(of: .text) {
          item.wrappedValue.rate = item.wrappedValue.rate.clamped(to: 0...1)
        }
      }
      .onDelete { indexSet in
        viewModel.priceInfo.regularTaxItems.remove(atOffsets: indexSet)
      }
      
      Button {
        withAnimation {
          viewModel.priceInfo.regularTaxItems.append(RateTaxItem.fresh())
        }
      } label: {
        Label { Text("Add New Regular Tax", comment: "Button title that adds a new regular tax entry") } icon: {
          AddNewItemImage()
        }
      }
      .alignmentGuide(.listRowSeparatorLeading) {
        $0[.leading]
      }
    }
  }
  
  var compoundTaxItems: some View {
    Group {
      ForEach($viewModel.priceInfo.compoundTaxItems) { item in
        VerticalField("Compound Tax") {
          HStack {
            TextField("Tax Name", text: item.name)
            TextField("", value: item.rate, format: .percent.sign(strategy: .never))
              .labelsHidden()
              .multilineTextAlignment(.trailing)
              .focused($focusField, equals: .taxRate(item.id))
#if os(iOS)
              .keyboardType(.decimalPad)
#endif
          }
        }
      }
      .onDelete { indexSet in
        viewModel.priceInfo.compoundTaxItems.remove(atOffsets: indexSet)
      }
      
      Button {
        withAnimation {
          viewModel.priceInfo.compoundTaxItems.append(RateTaxItem.fresh())
        }
      } label: {
        Label { Text("Add New Compound Tax", comment: "Button title that adds a new compound tax entry") } icon: {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(.white, .green)
        }
      }
      .alignmentGuide(.listRowSeparatorLeading) {
        $0[.leading]
      }
    }
  }
  
  var fixedTaxItems: some View {
    Group {
      ForEach($viewModel.priceInfo.fixedAmountTaxItems) { $item in
        VerticalField("Fixed Tax") {
          HStack {
            TextField("Tax Name", text: $item.name)
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
      }
      .onDelete { indexSet in
        viewModel.priceInfo.fixedAmountTaxItems.remove(atOffsets: indexSet)
      }
      
      Button {
        withAnimation {
          viewModel.priceInfo.fixedAmountTaxItems.append(FixedAmountItem.fresh())
        }
      } label: {
        Label { Text("Add New Fixed Amount Tax", comment: "Button title that adds a new fixed amount tax entry") } icon: {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(.white, .green)
        }
      }
      .alignmentGuide(.listRowSeparatorLeading) {
        $0[.leading]
      }
    }
  }
  
  @ViewBuilder
  var confirmationButton: some View {
    Button(editMode == .new ? "Add" : "Done") {
      
      // check tax items to see if they share names
      if viewModel.priceInfo.containsTaxItemsWithSameName {
        isShowingRepeatedTaxItemNameAlert = true
      } else {
        
        let resultItemTransaction = viewModel.updatedItemTransaction
        
        onCommit(resultItemTransaction, viewModel.saveAsItemTemplate)
        dismiss()
      }
    }
    .disabled(!viewModel.isValid)
  }
  
  var cancelButton: some View {
    Button("Cancel") {
      if viewModel.hasChanges {
        attemptToDiscardChanges = true
      } else {
        // onCommit(_:) called because there is a bug that causes animation stutters when cancelled
        if editMode == .edit {
          onCommit(viewModel.updatedItemTransaction, false)
        }
        dismiss()
      }
    }
  }
}

struct ItemTransactionEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ItemTransactionEditView(edit: .fresh()) { _, _ in }
        .environmentObject(InTransactDocument.mock())
    }
    .previewDisplayName("Edit")
    NavigationStack {
      ItemTransactionEditView { _, _ in
        // save ...
      }
      .environmentObject(InTransactDocument.mock())
    }
    .previewDisplayName("New")
  }
}
