//
//  Item.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/13/25.
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
