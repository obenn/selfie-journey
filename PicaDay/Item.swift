//
//  Item.swift
//  PicaDay
//
//  Created by Oliver Benning on 2026-09-05.
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
