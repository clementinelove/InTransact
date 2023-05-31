//
//  MockSampleData.swift
//  InTransact
//
//  Created by Yuhao Zhang on 2023-05-31.
//

import Foundation

class MockData {

  /// Change this to set the mock data language
  static let shared: MockData = english
  
  // load lazily
  static let chinese: MockData = { MockData(language: .chinese) }()
  static let english: MockData = { MockData(language: .english) }()
  
  let languageCode: Locale.LanguageCode
  
  
  init(language: Locale.LanguageCode) {
    self.languageCode = language
  }
    
  var keeperName: [String] {
    switch languageCode {
      case .chinese:
        return [ "张伟", "李娜", "王强", "刘芳", "陈敏", "杨辉", "黄明", "赵琳", "吴晨", "周燕", "郑丽", "朱辉", "马鹏", "孙红", "何欣", "罗峰", "高婷", "林华", "谢瑜", "雷阳", "苏熙", "乐荷", "雨翔", "冬雪", "柳春", "云曦", "夏阳", "岚清", "风铃", "溪月", "竹影", "海琴", "山韵", "诗瑶", "晓梦", "曜石", "静云", "星辰", "紫萱", "慕晴", "杨春华", "刘雨萌", "陈若瑶", "孙博文", "赵晨阳", "张晓莉", "王静怡", "郑海宁", "韩紫萍", "周星辰", "李铭宇", "姚语嫣", "高雅琳", "唐志豪", "许思雨", "魏晴燕", "曾浩然", "叶婷婷", "蔡秋枫", "康明洋",
        ]
      default:
        return [
          "Evelyn Hartman", "Benjamin Wolfe", "Victoria Sinclair", "Harrison Monroe", "Penelope Archer", "Sebastian Drake", "Isabella Montgomery", "Oliver Sullivan", "Amelia Fitzgerald", "Gabriel Harrison",
        ]
    }
  }
  
  var companyName: [String] {
    switch languageCode {
      case .chinese:
        return [
          "先驱科技", "创数", "点智", "优能", "智库", "食享", "美口", "食新", "舌尖", "美味道", "媒点", "创艺", "影趣", "悦目", "创享", "元气", "健形", "心身", "健快", "运享", "行点", "游站", "住好", "游趣", "旅玩",
        ]
      default: // english
        return [
          "StellarEdge", "TechVista", "FusionSphere", "BrightWave", "VertexPrime", "NovaTech", "Synthex Solutions", "QuantumLeap", "Innovatix", "ProximaTech", "NexusConnect", "Innovexa", "PentaByte", "ApexSynergy", "ElectraSys", "LumosTech", "DynaCore", "VividWave", "SpectraLink", "CygnusTech",
        ]
    }
  }
  
  var transactionComment: [String] {
    switch languageCode {
      case .chinese:
        return [
          "购买商品A和商品B",
          "付款订单#12345，包括运费和税费",
          "服务费用支付，附加定制功能",
          "退款处理-订单#67890，退回原支付方式",
          "购物车结算-优惠券使用，折扣金额：$20",
          "订阅续订-月度会员，有效期至2024年5月",
          "充值账户余额，充值金额：$50",
          "押金退还-租赁物品，退还到信用卡账户",
          "活动报名费支付，包括附加工作坊费用",
          "提现-银行转账，转账至指定银行账户",
        ]
      default: // english
        return [
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
    }
  }
  
  var itemAndVariantName: [(item: String, variant: String)] {
    switch languageCode {
      case .chinese:
        return [
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
      default:
        return [
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
    }
  }
  
  var taxName: [String] {
    switch languageCode {
      case .chinese:
        return [
          "创新发展税",
          "平等贡献税",
          "美好未来税",
          "共享经济税",
          "智能科技税",
          "绿色可持续税",
          "人文进步税",
          "数字化转型税",
          "社会公益税",
          "幸福生活税",
        ]
      default: return [
        "IDT", // Innovation Development Tax
        "ECT", // Equal Contribution Tax
        "BFT", // Bright Future Tax
        "SET", // Shared Economy Tax
        "STT", // Smart Technology Tax
        "GST", // Green Sustainability Tax
        "HPT", // Humanistic Progress Tax
        "DTT", // Digital Transformation Tax
        "SWT", // Social Welfare Tax
        "JLT", // Joyful Living Tax
      ]
    }
  }
  
  var postalAddress: [String] {
    switch languageCode {
      case .chinese: return [
        "上海市浦东新区王江高科技园区123号",
        "北京市朝阳区建国路456号",
        "广东省深圳市福田区华强南路789号",
        "江苏省南京市玄武区中山西路987号",
        "浙江省杭州市西湖区文二东路654号",
      ]
        
      default: return [
        "123 Mockingbird Lane, Anytown, USA, 12345",
        "456 Elm Street, Fictionville, Canada, A1 2C3",
        "789 Maple Avenue, Imaginary City, XYZ 98765",
        "987 Willow Lane, Fantasyland, Australia, 54321",
        "654 Oak Street, Dreamville, UK, AB1 3CD",
        "12 Main Street, Mockington, USA, 54321",
        "45 Pine Avenue, Imaginaria, Canada, M0 0K0",
        "78 Oak Drive, Fictionville, Australia, 98765",
        "98 Elm Court, Dreamland, UK,, AB1 3EF",
        "65 Maple Lane, Fantasyville, Germany, 12345",
      ]
    }
  }
  
  var contactComment: [String] {
    switch languageCode {
      case .chinese: return [
        "业务经理 - 负责销售和合作事务",
        "客户服务代表 - 处理客户查询和问题",
        "采购主管 - 负责供应链和采购管理",
        "市场营销专员 - 策划和执行市场活动",
        "技术支持工程师 - 提供技术支持和解决方案",
        "财务经理 - 负责财务管理和预算控制",
        "人力资源主管 - 管理员工招聘和培训",
        "项目经理 - 负责项目执行和交付",
        "品牌经理 - 策划和推广品牌活动",
        "运营主管 - 管理日常运营和流程优化",
      ]
      default: return [
        "Account Manager - Responsible for sales and partnership matters",
        "Customer Service Representative - Handles customer inquiries and issues",
        "Procurement Supervisor - Manages supply chain and procurement",
        "Marketing Specialist - Plans and executes marketing campaigns",
        "Technical Support Engineer - Provides technical support and solutions",
        "Finance Manager - Responsible for financial management and budget control",
        "HR Supervisor - Oversees employee recruitment and training",
        "Project Manager - Manages project execution and delivery",
        "Brand Manager - Plans and promotes brand activities",
        "Operations Supervisor - Manages day-to-day operations and process optimization"
      ]
    }
  }
  
}
