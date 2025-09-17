//
//  Quote.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//

import Foundation
import SwiftData


@Model
class Quote: Identifiable {
    @Attribute(.unique) var id: UUID
    var text: String
    var author: String?
    var category: String?
    var isCustom: Bool
    var isFavorite: Bool = false
    
    init(id: UUID = UUID(), text: String, author: String? = nil, category: String? = "", isCustom: Bool = false, isFavorite: Bool = false) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
        self.isCustom = isCustom
    }
}
