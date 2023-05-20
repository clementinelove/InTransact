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
  
  init(edit transaction: ItemTransaction = ItemTransaction.fresh()) {
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
                    priceInfo: priceInfo)
  }
}
// MARK: - View
struct ItemTransactionEditView: View {
  
  static let verticalLabelFont: Font = .caption
  
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
  @EnvironmentObject private var document: InAndOutDocument
  
  private let editMode: EditMode
  private let onCommit: ((ItemTransaction) -> Void)
  
  init(edit item: ItemTransaction, onCommit: @escaping (ItemTransaction) -> Void) {
    self.editMode = .edit
    self._viewModel = StateObject(wrappedValue: ItemTransactionViewModel(edit: item))
    self.onCommit = onCommit
  }
  
  init(onSave: @escaping (ItemTransaction) -> Void) {
    self.editMode = .new
    self._viewModel = StateObject(wrappedValue: ItemTransactionViewModel())
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
        VStack(alignment: .leading) {
          
          Text("\(priceLabel) (\(document.content.settings.currencyIdentifier))") 
            .font(Self.verticalLabelFont)
          
            CurrencyTextField(amount: $viewModel.priceInfo.price,
                              focusedBinding: $focusField, value: .price,
                              alignment: .leading)
              .labelsHidden()
            #if os(iOS)
              .keyboardType(.decimalPad)
            #endif
              .multilineTextAlignment(.trailing)
          
        }
        
        quantityInputControl

      } footer: {
        Text("\(Global.appName) can calculate average unit price for you if the price type is not unit price.")
        // TODO: maybe specify how it's rounded?
      }
      
      // MARK: Tax Rates

        Section {
          regularTaxItems
          compoundTaxItems
          fixedTaxItems
          
        } header: {
          Text("Tax Info")
        } footer: {
          Text("A regular tax is calculated based on its price before tax; a compound tax is calculated after all regular tax were applied.")
          // TODO: show examples in a sheet
        }
      
      // MARK: Explicit Price after tax section
      if viewModel.priceInfo.priceType == .perUnitBeforeTax ||
          viewModel.priceInfo.priceType == .sumBeforeTax {
        Section {
          Toggle(isOn: $viewModel.hasExplicitAfterTaxTotal.animated) {
            Text("Explicit After Tax Total")
          }
          if viewModel.hasExplicitAfterTaxTotal {
            VStack(alignment: .leading) {
              Text("After Tax Total (\(document.content.settings.currencyIdentifier))")
                .font(Self.verticalLabelFont)
              
              CurrencyTextField(amount: $viewModel.explicitAfterTaxTotal,
                                focusedBinding: $focusField,
                                value: Field.explicitTotalAfterTax,
                                alignment: .leading)
                  .labelsHidden()
#if os(iOS)
                  .keyboardType(.decimalPad)
#endif
                  .multilineTextAlignment(.trailing)
              
            }
          }
        } footer: {
          Text("You can explicitly specifiy the after-tax total for this entry, it will be used to calculate the total of the whole transaction directly.")
        }
      }
      
      
      Section {
        Toggle("Save Item Info as Template", isOn: $viewModel.saveAsItemTemplate)
      } footer: {
        Text("Save these information as template when the transaction is saved. This will override exising template for the same item name and variant.")
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
        .toolbarRole(.navigationStack)
      }
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
    editMode == .edit ? "Edit Item" : "New Item"
  }
  
  var quantityInputControl: some View {
    VStack(alignment: .leading) {
        
        Text("Quantity")
          .font(Self.verticalLabelFont)
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
        
      
    }
  }
  
  var priceLabel: String {
    switch viewModel.priceInfo.priceType {
      case .perUnitBeforeTax:
        return "Unit Price Before Tax"
      case .perUnitAfterTax:
        return "Unit Price After Tax"
      case .sumBeforeTax:
        return "Sum Price Before Tax"
      case .sumAfterTax:
        return "Sum Price After Tax"
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
        VStack(alignment: .leading) {
          Text("Regular Tax")
            .font(Self.verticalLabelFont)
          HStack {
            TextField("Tax Name", text: item.name)
            TextField("", value: item.rate, format: .percent)
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
        viewModel.priceInfo.regularTaxItems.remove(atOffsets: indexSet)
      }
      
      Button {
        withAnimation {
          viewModel.priceInfo.regularTaxItems.append(RateTaxItem.fresh())
        }
      } label: {
        Label { Text("Add New Regular Tax") } icon: {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(.white, .green)
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
        VStack(alignment: .leading) {
          Text("Compound Tax")
            .font(Self.verticalLabelFont)
          HStack {
            TextField("Tax Name", text: item.name)
            TextField("", value: item.rate, format: .percent)
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
        Label { Text("Add New Compound Tax") } icon: {
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
        VStack(alignment: .leading) {
          Text("Fixed Tax")
            .font(Self.verticalLabelFont)
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
        Label { Text("Add New Fixed Amount Tax") } icon: {
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
      let resultItemTransaction = viewModel.updatedItemTransaction
      if viewModel.saveAsItemTemplate {
        document.content.saveAsTemplate(resultItemTransaction)
      }
      
      onCommit(resultItemTransaction)
      dismiss()
    }
    .disabled(!viewModel.isValid)
  }
  
  var cancelButton: some View {
    Button("Cancel") {
      if viewModel.hasChanges {
        attemptToDiscardChanges = true
      } else {
        dismiss()
      }
    }
  }
}

struct ItemTransactionEditView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ItemTransactionEditView(edit: .fresh()) { _ in }
        .environmentObject(InAndOutDocument.mock())
    }
    .previewDisplayName("Edit")
    NavigationStack {
      ItemTransactionEditView { _ in
        // save ...
      }
      .environmentObject(InAndOutDocument.mock())
    }
    .previewDisplayName("New")
  }
}