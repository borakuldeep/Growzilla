//  CustomQuotesView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

struct CustomQuotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Quote> { $0.isCustom }) private var customQuotes:
        [Quote]
    @Binding var selectedQuote: Quote?
    @Binding var showingDetail: Bool
    @State private var showingCreateQuote = false

    var localQuotes = [] as [Quote]

    var body: some View {
        NavigationStack {
            List {
                Section("Custom Quotes") {
                    if customQuotes.isEmpty && localQuotes.isEmpty {
                        Text("No custom quotes yet")
                            .foregroundColor(.secondary)
                    } else {
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
                                        Label("Unfavorite", systemImage: "heart.slash")
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
//                            .onTapGesture {
//                                selectedQuote = quote
//                                //showingDetail = true
//                                showingCreateQuote = true
//                                isReadOnly = true
//                            }
                        }
                    }
                }
            }
            //.background(Color(hex: 0xFCF5EB))
            .navigationTitle("Custom Quotes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        showingCreateQuote = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateQuote) {
                QuoteCreationView(
                    showingCreateQuote: $showingCreateQuote,
                    selectedQuote: $selectedQuote,
                )
            }
//            .sheet(isPresented: $showingDetail) {
//                QuoteDetailView(quote: selectedQuote)
//            }
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
        selectedQuote: .constant(nil),
        showingDetail: .constant(false),
        localQuotes: sampleQuotes
    )
    .modelContainer(for: Quote.self, inMemory: true)
}
