//
//  QuoteReminder.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//


//  QuoteReminder.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import Foundation

@Model
class QuoteReminder {
    @Attribute(.unique) var quoteID: UUID
    var reminderOption: String
    
    init(quoteID: UUID, reminderOption: String) {
        self.quoteID = quoteID
        self.reminderOption = reminderOption
    }
}
