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

import SwiftData
import SwiftUI

struct QuoteCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingCreateQuote: Bool
    //@Binding var selectedQuote: Quote?
    @State private var text: String = ""
    @State private var author: String = ""
    @State private var isFavorite: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Quote")) {
                    TextField("Quote text", text: $text, axis: .vertical)
                        .lineLimit(3...5)
                    TextField("Author (optional)", text: $author)
                    Toggle("Favorite", isOn: $isFavorite).disabled(true)
                }
                Section {
                    Text(
                        "You can schedule this quote from the favorites view if you like."
                    ).font(.subheadline)
                }
                Section {
                    Text(
                        "Scheduling a daily fix quote can be used for positive affirmation or motivational purposes."
                    ).font(.subheadline).opacity(0.7)
                }
            }
            .gradientBackground()
            .navigationTitle("Add Quote")
            .scrollContentBackground(.hidden)
//            .background(
//                colorScheme == .dark
//                    ? Color(hex: "#454545") : Color(hex: "#FFFAF5")
//            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateQuote = false
                    }.foregroundStyle(colorScheme == .dark ? .white : .blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newQuote = Quote(
                            text: text,
                            author: author.isEmpty ? nil : author,
                            isCustom: true
                        )
                        newQuote.isFavorite = isFavorite
                        modelContext.insert(newQuote)
                        try? modelContext.save()
                        showingCreateQuote = false
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
    }
}

#Preview {
    QuoteCreationView(showingCreateQuote: .constant(true))
        .modelContainer(for: Quote.self, inMemory: true)
}
