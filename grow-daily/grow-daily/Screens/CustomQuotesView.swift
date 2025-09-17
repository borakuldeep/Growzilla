//  CustomQuotesView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

struct CustomQuotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(filter: #Predicate<Quote> { $0.isCustom }) private var customQuotes:
        [Quote]
    //@Binding var selectedQuote: Quote?
    @Binding var showingDetail: Bool
    @State private var showingCreateQuote = false
    @State private var searchText = ""

    var localQuotes = [] as [Quote]
    
    var filteredQuotes: [Quote] {
        let allQuotes = customQuotes + localQuotes
        if searchText.isEmpty {
            return allQuotes
        } else {
            return allQuotes.filter { quote in
                quote.text.lowercased().contains(searchText.lowercased()) ||
                (quote.author?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    @ViewBuilder
    private var QuoteList: some View {
            ForEach(customQuotes + localQuotes) { quote in
                VStack(alignment: .leading) {
                    Text(quote.text)
                    if let author = quote.author {
                        Text(author).font(.subheadline)
                    }
                }
                .swipeActions {
                    Button {
                        quote.isFavorite.toggle()
                        try? modelContext.save()
                    } label: {
                        if quote.isFavorite {
                            Label(
                                "Unfavorite",
                                systemImage: "heart.slash"
                            )
                        } else {
                            Label("Favorite", systemImage: "heart")
                        }
                    }
                    .tint(.pink)

                    Button(role: .destructive) {
                        modelContext.delete(quote)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
    }

    var body: some View {
        NavigationStack {
            VStack {
            List {
                Section("Custom Quotes") {
                    if customQuotes.isEmpty && localQuotes.isEmpty {
                        Text("No custom quotes yet")
                            .foregroundColor(.secondary)
                    } else {
                        QuoteList
                    }
                }
            }
            //.background(Color(hex: 0xFCF5EB))
            .scrollContentBackground(.hidden)
            .navigationTitle("My custom quotes")
            .searchable(text: $searchText, prompt: "Search quotes or authors").disabled(customQuotes.isEmpty)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingCreateQuote = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(colorScheme == .dark ? .white : .blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateQuote) {
                QuoteCreationView(
                    showingCreateQuote: $showingCreateQuote
                )
            }
        }
            .gradientBackground()
        }
    }
}

#Preview {

    let sampleQuotes = [
        Quote(
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            isFavorite: true
        ),
        Quote(
            text: "Stay hungry, stay foolish.",
            author: "Steve Jobs",
            isFavorite: false
        ),
        Quote(
            text: "Be the change you wish to see in the world.",
            author: "Mahatma Gandhi",
            isFavorite: true
        ),
    ]
    CustomQuotesView(
        showingDetail: .constant(false),
        localQuotes: [] //sampleQuotes
    )
    .modelContainer(for: Quote.self, inMemory: true)
}
