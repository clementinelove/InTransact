//
//  Mock.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import Foundation
import DequeModule

// TODO: Deque Module is everywhere and it's not necessary

extension INTDocument {
  static func mock() -> Self {
//    INTDocument()
    
    INTDocument(settings: Setting(),
                itemTemplates: [
                  .mock(),
                  .mock()
                ], contactTemplates: [
                  .mock(),
                  .mock()
                ],
                transactions: (0...10).map { _ in .mock() })
  }
}

extension Transaction {
  
  static func mock() -> Transaction {
    Transaction(transactionType: TransactionType.allCases.randomElement()!,
                transactionID: UUID().uuidString,
                invoiceID: "123142312",
                counterpartyContact: .mock(),
                subtransactions: (0...(1...20).randomElement()!).map { _ in .mock() },
                fixedCosts: [.init(name: "Delivery", amount: 12.56)],
                comment: Bool.random() ? "" : MockData.shared.transactionComment.randomElement()!,
                keeperName: Bool.random() ? MockData.shared.keeperName.randomElement()! : nil,
                date: Date.now.addingTimeInterval(Double(((-60 * 60 * 24 * 180)...0).randomElement()!)))
  }
}



extension ItemTransaction {
  
  static func mock() -> ItemTransaction {
    let randomItem = MockData.shared.itemAndVariantName.randomElement()!
    return ItemTransaction(itemID: nil, itemName: randomItem.item, variant: randomItem.variant, priceInfo: .mock())
  }
}

extension ItemTemplate {
  static func mock() -> ItemTemplate {
    let itemAndVariant = MockData.shared.itemAndVariantName.randomElement()!
    return ItemTemplate(itemName: itemAndVariant.item,
                 variantName: itemAndVariant.variant,
                 priceInfo: .fresh())
  }
}

extension PriceInfo {
  static func mock() -> Self {
    let d = Decimal((0...300).randomElement()!)
    return PriceInfo(price: d, priceType: .perUnitBeforeTax,
                     quantity: (1...5).randomElement()!,
                     regularTaxItems: [.init(name: MockData.shared.taxName.randomElement()!, rate: 0.05)],
                     compoundTaxItems: [.init(name: MockData.shared.taxName.randomElement()!, rate: 0.1)],
                     fixedAmountTaxItems: [.init(name: MockData.shared.taxName.randomElement()!, amount: 10.5)])
  }
}

extension Contact {
  static func mock() -> Self {
    let mockPostalAddress = MockData.shared.postalAddress.randomElement()!
    return Contact(isCompany: .random(),
                   name: MockData.shared.keeperName.randomElement()!,
                   companyName: MockData.shared.companyName.randomElement()!,
                   email: "johndoe@example.com",
                   phoneNumber: "+00 1234567890",
                   account: "23-12-25 12345678",
                   taxID: "082314123",
                   address: mockPostalAddress,
                   notes: MockData.shared.contactComment.randomElement()!)
  }
}

extension ContactTemplate {
  static func mock() -> Self {
    return ContactTemplate(contact: .mock())
  }
}
