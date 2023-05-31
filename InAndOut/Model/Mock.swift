//
//  Mock.swift
//  My App
//
//  Created by Yuhao Zhang on 2023-05-06.
//

import Foundation
import DequeModule

// TODO: Deque Module is everywhere and it's not necessary

extension InTransactDocument {
  static func mock() -> InTransactDocument {
    InTransactDocument(mock: true)
  }
}

extension INTDocument {
  static func mock() -> Self {
//    INTDocument()
    INTDocument(settings: Setting(),
                itemTemplates: [
                  ItemTemplate(itemName: "Burger",
                               variantName: "Whooper",
                               priceInfo: .fresh())
                ],
                transactions: (0...10).map { _ in .mock() })
  }
}

extension Transaction {
  
  static let comments = [
    "Office supplies for May 2023",
    "Monthly rent payment for June 2023",
    "Payment to vendor for consulting services",
    "Employee payroll for May 2023",
    "Business insurance premium for Q2 2023",
    "Purchase of new computer equipment",
    "Advertising expenses for May 2023",
    "Payment to utility company for electricity and gas",
    "Quarterly \"tax payment\" for Q2 2023", // double quotes for testing with csv
    "Reimbursement for employee travel expenses",
    "Payment to landlord for office space lease",
    "Investment in new marketing campaign",
    "Payment to legal services for business consultation",
    "Purchase of inventory for retail store",
    "Payment to shipping and handling company for product distribution",
    "Payment to website hosting company for monthly hosting fees",
    "Travel expenses for business conference",
    "Payment to accountant for bookkeeping services",
    "Payment to marketing agency for social media advertising",
    "Purchase of new office furniture",
    "Payment to cleaning service for office maintenance",
    "Donation to local charity",
    "Payment to web designer for website redesign",
    "Payment to software company for new software licenses",
    "Payment to printing company for marketing materials",
    "Payment to courier service for package delivery",
    "Payment to catering service for employee event",
    "Payment to data backup service for data storage",
    "Payment to telecommunications company for internet and phone services",
    "Payment to financial advisor for investment consultation.",
  ]
  
  static func mock() -> Transaction {
    Transaction(transactionType: TransactionType.allCases.randomElement()!,
                transactionID: UUID().uuidString,
                invoiceID: "123142312",
                counterpartyContact: .mock(),
                subtransactions: (0...(1...20).randomElement()!).map { _ in .mock() },
                fixedCosts: [.init(name: "Delivery", amount: 12.56)],
                comment: Bool.random() ? "" : Self.comments.randomElement()!,
                keeperName: Bool.random() ? sampleKeeperNames.randomElement()! : nil,
                date: Date.now.addingTimeInterval(Double(((-60 * 60 * 24 * 180)...0).randomElement()!)))
  }
}

// MARK: zh-sc
fileprivate let sampleItemNames: [(String, String)] = [
  ("经典美式堡", ""),
  ("香浓奶酪堡", ""),
  ("烤鸡肉堡", ""),
  ("牛肉芝士堡", "加1份肉饼"),
  ("火腿菠萝堡", ""),
  ("墨西哥辣味堡", ""),
  ("意大利香肠堡", ""),
  ("三明治堡", "不加芝士"),
  ("健康蔬菜堡", ""),
  ("豪华双层堡", ""),
  ("烟熏培根堡", ""),
  ("香辣鱼肉堡", ""),
  ("田园鸡蛋堡", ""),
  ("贵族蓝奶酪堡", "少放奶酪"),
  ("黑椒牛肉堡", ""),
  ("烧烤堡", ""),
  ("夏威夷风情堡", ""),
  ("奥尔良鸡肉堡", ""),
  ("咖喱鸡肉堡", ""),
  ("鳕鱼堡", ""),
]
fileprivate let sampleKeeperNames: [String] = [
  "张伟",
  "李娜",
  "王强",
  "刘芳",
  "陈敏",
  "杨辉",
  "黄明",
  "赵琳",
  "吴晨",
  "周燕",
  "郑丽",
  "朱辉",
  "马鹏",
  "孙红",
  "何欣",
  "罗峰",
  "高婷",
  "林华",
  "谢瑜",
  "雷阳",
  "苏熙",
  "乐荷",
  "雨翔",
  "冬雪",
  "柳春",
  "云曦",
  "夏阳",
  "岚清",
  "风铃",
  "溪月",
  "竹影",
  "海琴",
  "山韵",
  "诗瑶",
  "晓梦",
  "曜石",
  "静云",
  "星辰",
  "紫萱",
  "慕晴",
  "杨春华",
  "刘雨萌",
  "陈若瑶",
  "孙博文",
  "赵晨阳",
  "张晓莉",
  "王静怡",
  "郑海宁",
  "韩紫萍",
  "周星辰",
  "李铭宇",
  "姚语嫣",
  "高雅琳",
  "唐志豪",
  "许思雨",
  "魏晴燕",
  "曾浩然",
  "叶婷婷",
  "蔡秋枫",
  "康明洋",
]

/*
fileprivate let sampleItemNames: [(String, String)] = [
  ("Stainless Steel Water Bottle", "H2O-PRO 500"),
  ("Bluetooth Wireless Earbuds", "SonicBuds S7"),
  ("4K Ultra HD Smart TV", "VisionMax 8000"),
  ("Yoga Mat with Strap", "FlexiMat X"),
  ("Electric Toothbrush", "SonicClean 3000"),
  ("Portable Power Bank", "PowerBoost 20000"),
  ("Non-Stick Frying Pan", "ProCook Plus"),
  ("Noise Cancelling Headphones", "AudioShield Pro"),
  ("Digital Kitchen Scale", "AccuWeigh 5000"),
  ("Resistance Bands Set", "FlexiFit Pro"),
  ("Wireless Charging Pad", "ChargeMate 3.0"),
  ("Air Fryer with Digital Display", "CrispCook Elite"),
  ("Polarized Sunglasses", "SunGuard 300"),
  ("Smart Thermostat for Home", "ClimateControl 9000"),
  ("High-Speed Blender with Pitcher", "NutriBlend X"),
  ("Memory Foam Mattress Topper", "DreamCloud Elite"),
  ("Fitness Tracker Watch", "PulseMax 500"),
  ("USB-C Hub Adapter for MacBook", "ThunderLink Pro"),
  ("Handheld Vacuum Cleaner", "DustBuster 2000"),
  ("Reusable Silicone Food Bags", "FreshSeal"),
  ("Electric Kettle with Temperature Control", "KettleMax"),
  ("Smart Lock for Front Door", "SecureMax Pro"),
  ("Compact Air Purifier", "AirPure 100"),
  ("Automatic Soap Dispenser", "CleanFoam"),
  ("Foldable Laptop Stand", "LapMate 500"),
  ("Stainless Steel Travel Mug", "TravelerPro 20"),
  ("Multi-Port USB Wall Charger", "PowerMate 8"),
  ("Wireless Gaming Mouse", "EliteGamer Pro"),
  ("Ceramic Space Heater with Remote", "WarmZone 3000"),
  ("Foam Roller for Deep Tissue Massage", "FlexiRoller X")
]
fileprivate let sampleKeeperNames: [String] = [
  "Evelyn Hartman",
  "Benjamin Wolfe",
  "Victoria Sinclair",
  "Harrison Monroe",
  "Penelope Archer",
  "Sebastian Drake",
  "Isabella Montgomery",
  "Oliver Sullivan",
  "Amelia Fitzgerald",
  "Gabriel Harrison",
]
 */
extension ItemTransaction {
  
  static func mock() -> ItemTransaction {
    let randomItem = sampleItemNames.randomElement()!
    return ItemTransaction(itemID: nil, itemName: randomItem.0, variant: randomItem.1, priceInfo: .mock())
  }
}

extension PriceInfo {
  static func mock() -> Self {
    let d = Decimal((0...300).randomElement()!)
    return PriceInfo(price: d, priceType: .perUnitBeforeTax,
                     quantity: (1...5).randomElement()!,
                     regularTaxItems: [.init(name: "GST", rate: 0.05)],
                     compoundTaxItems: [.init(name: "PST", rate: 0.1)],
                     fixedAmountTaxItems: [.init(name: "Tariff", amount: 10.5)])
  }
}

extension ItemTemplate {
  static func mock() -> Self {
    let item = sampleItemNames.randomElement()!
    return ItemTemplate(itemName: item.0,
                 variantName: item.1,
                 priceInfo: .mock())
  }
}

extension Contact {
  static func mock() -> Self {
    return Contact(isCompany: .random(),
                   name: sampleKeeperNames.randomElement()!,
                   companyName: "Smart Kitchen",
                   email: "johndoe@example.com",
                   phoneNumber: "+00 1234567890",
                   taxID: "082314123",
                   address: "James Awkward Street\nRoom 131\nEdinburgh\nScotland",
                   postalCode: "EH1 XXX",
                   notes: "Nothing to say")
  }
}
