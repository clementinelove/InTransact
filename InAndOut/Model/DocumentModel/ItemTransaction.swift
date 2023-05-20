//
//  ItemTransaction.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-19.
//

import Foundation
import CoreTransferable

extension ItemTransaction: Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .itemTransaction)
  }
}


public struct ItemTransaction: Identifiable, Codable, Equatable {
  public typealias ID = UUID
  
  public static func == (lhs: ItemTransaction, rhs: ItemTransaction) -> Bool {
    lhs.id == rhs.id && lhs.itemID == rhs.itemID && lhs.itemName == rhs.itemName
    && lhs.variant == rhs.variant && lhs.priceInfo == rhs.priceInfo
  }
  
  public var id: ID = ID()
  //  @Published var item: Item
  var itemID: String?
  var itemName: String
  var variant: String?
  
  var priceInfo: PriceInfo
  
  public static func fresh() -> ItemTransaction {
    ItemTransaction(itemID: nil, itemName: "", variant: nil, priceInfo: PriceInfo.fresh())
  }
  
  public init(id: ID = ID(),
              itemID: String? = nil,
              itemName: String,
              variant: String? = nil,
              priceInfo: PriceInfo) {
    self.id = id
    self.itemID = itemID
    self.itemName = itemName
    self.variant = variant
    self.priceInfo = priceInfo
  }
}
