//  ScheduledQuote.swift
//  Quotes
//
//  Created by Grok on 9/8/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import Foundation

@Model
class ScheduledQuote {
    @Attribute(.unique) var id: UUID
    var quoteID: UUID
    var startDate: Date
    var duration: Int  // In days
    var notificationTime: Date
    
    init(id: UUID = UUID(), quoteID: UUID, startDate: Date = Date(), duration: Int, notificationTime: Date = Date()) {
        self.id = id
        self.quoteID = quoteID
        self.startDate = startDate
        self.duration = duration
        self.notificationTime = notificationTime
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
    }
    
    var isActive: Bool {
        Date() >= startDate && Date() < endDate
    }
}
