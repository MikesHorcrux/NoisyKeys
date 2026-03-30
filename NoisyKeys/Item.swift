//
//  Item.swift
//  NoisyKeys
//
//  Created by Mike  Van Amburg on 3/29/26.
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
