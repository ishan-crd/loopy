//
//  Item.swift
//  loopy
//
//  Created by Ishan Gupta on 11/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
