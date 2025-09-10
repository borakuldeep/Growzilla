
//
//  QuoteCreationView.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//


//  QuoteCreationView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI
import SwiftData

struct QuoteCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showingCreateQuote: Bool
    @Binding var selectedQuote: Quote?
    @State private var text: String = ""
    @State private var author: String = ""
    @State private var isFavorite: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Quote")) {
                    TextField("Quote text", text: $text, axis: .vertical)
                        .lineLimit(3...5)
                    TextField("Author (optional)", text: $author)
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Add Quote")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateQuote = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newQuote = Quote(text: text, author: author.isEmpty ? nil : author, isCustom: true)
                        newQuote.isFavorite = isFavorite
                        modelContext.insert(newQuote)
                        try? modelContext.save()
                        selectedQuote = newQuote
                        showingCreateQuote = false
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    QuoteCreationView(showingCreateQuote: .constant(true), selectedQuote: .constant(nil))
        .modelContainer(for: Quote.self, inMemory: true)
}

