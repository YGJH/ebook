//
//  Item.swift
//  superPiyan
//
//  Created by user20 on 2025/10/9.
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
