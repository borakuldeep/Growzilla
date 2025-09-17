//
//  QuoteUtils.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/16/25.
//

import SwiftData
import Foundation

struct QuoteDTO: Codable {
    let text: String
    let author: String
    let category: String
}

func loadQuotes(from file: String) throws -> [QuoteDTO] {
    guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "File \(file).json not found"])
    }
    
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode([QuoteDTO].self, from: data)
}

func combineShuffleAndStoreQuotes(for categories: [String], using categoryToFileMap: [String: String], in modelContext: ModelContext) throws {
    // Combine quotes from all specified categories
    var combinedQuotes: [QuoteDTO] = []
    
    for category in categories {
        guard let fileName = categoryToFileMap[category] else {
            throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No file mapped for category \(category)"])
        }
        let quotes = try loadQuotes(from: fileName)
        combinedQuotes.append(contentsOf: quotes)
    }
    
    // Shuffle the combined quotes
    combinedQuotes.shuffle()
    
    print("combined quotes count: \(combinedQuotes.count)")
    
    // Store in SwiftData
    for quoteDTO in combinedQuotes {
        let quote = Quote(text: quoteDTO.text, author: quoteDTO.author, category: quoteDTO.category)
        modelContext.insert(quote)
    }
    
    // Save the context
    try modelContext.save()
}

func processQuotes(for selectedCategories: [String],in modelContext: ModelContext) {
    do {
        // Define the category-to-file mapping
        let categoryToFileMap = [
            "Health": "HealthQuotes",
            "Motivational": "MotivationalQuotes",
            "Wealth": "WealthQuotes",
            "Life Wisdom": "WisdomQuotes",
        ]
        
        //map user selected categories to above mapping
        
        // Call the function
        try combineShuffleAndStoreQuotes(for: selectedCategories, using: categoryToFileMap, in: modelContext)
        print("Quotes for categories \(selectedCategories) successfully combined, shuffled, and stored.")
    } catch {
        print("Error processing quotes: \(error)")
    }
}
