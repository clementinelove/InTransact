//
//  SVBuilder.swift
//  Seperated Value Builder
//  InAndOut
//
//  Created by Yuhao Zhang on 2023-05-18.
//

import Foundation

public func buildRow(_ cells: [String], separator: String, recordSeperator: String) -> String {
  cells.joined(separator: separator).appending(recordSeperator)
}
