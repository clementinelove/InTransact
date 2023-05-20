//
//  Copyable.swift
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-14.
//

import Foundation

protocol Copyable {
  
  init(copy: Self)
}

extension Copyable {
  func copy() -> Self {
    return Self.init(copy: self)
  }
}

// Made itself a replicate of another self
protocol Replicatable {
  func replicate(from other: Self)
}
