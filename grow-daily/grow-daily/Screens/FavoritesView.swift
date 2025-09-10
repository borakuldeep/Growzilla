//  FavoritesView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Quote> { $0.isFavorite }) private
        var favoriteQuotes: [Quote]
    @Query(sort: \ScheduledQuote.startDate, order: .reverse) private
        var scheduledQuotes: [ScheduledQuote]
    @Binding var selectedQuote: Quote?
    @Binding var showingDetail: Bool
    @State private var showingScheduleSheet = false
    @State private var schedulingQuote: Quote?
    var localQuotes = [] as [Quote]

    var activeScheduledQuoteID: UUID? {
        if let scheduled = scheduledQuotes.first {
            let endDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: scheduled.duration,
                    to: scheduled.startDate
                ) ?? Date()
            if Date() >= scheduled.startDate && Date() < endDate {
                return scheduled.quoteID
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Favorite Quotes") {
                    if favoriteQuotes.isEmpty && localQuotes.isEmpty {
                        Text("No favorite quotes yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(favoriteQuotes + localQuotes) { quote in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(quote.text)
                                    if let author = quote.author {
                                        Text(author).font(.subheadline)
                                    }
                                }
                                .padding(2)
                                //                                .background(quote.id == activeScheduledQuoteID ? Color.green.opacity(0.1) : Color.clear)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Button(action: {
                                        schedulingQuote = quote
                                        showingScheduleSheet = true
                                    }) {
                                        Image(
                                            systemName: quote.id
                                                == activeScheduledQuoteID
                                                ? "clock.fill" : "clock"
                                        )
                                        .foregroundColor(
                                            quote.id == activeScheduledQuoteID
                                                ? .white : .gray
                                        )
                                    }
                                    .padding(8)
                                    .background(
                                        quote.id == activeScheduledQuoteID
                                            ? .green : .clear
                                    )
                                    if quote.id == activeScheduledQuoteID {
                                        Text("scheduled").font(.subheadline).foregroundColor(.green)
                                    }
                                    
                                }
                                

                            }
                            .swipeActions {
                                Button {
                                    quote.isFavorite.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Label(
                                        "Unfavorite",
                                        systemImage: "heart.slash"
                                    )
                                }
                                .tint(.pink)
                            }
                        }
                    }
                }
            }

            .navigationTitle("Favorites")
            .sheet(isPresented: $showingScheduleSheet) {
                ScheduleSheet(
                    schedulingQuote: $schedulingQuote,
                    showingScheduleSheet: $showingScheduleSheet
                )
            }
            //            .sheet(isPresented: $showingDetail) {
            //                if let quote = selectedQuote {
            //                    QuoteDetailView(quote: quote)
            //                }
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
            isFavorite: true
        ),
        Quote(
            text: "Be the change you wish to see in the world.",
            author: "Mahatma Gandhi",
            isFavorite: true
        ),
    ]
    FavoritesView(
        selectedQuote: .constant(nil),
        showingDetail: .constant(false),
        localQuotes: sampleQuotes
    )
    .modelContainer(for: [Quote.self, ScheduledQuote.self], inMemory: true)

}

// PreviewProvider to replace #Preview
//struct FavoritesView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Create an in-memory model container
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try! ModelContainer(for: Quote.self, ScheduledQuote.self, configurations: config)
//
//        // Insert sample favorite quotes
//        let context = container.mainContext
//        let sampleQuotes = [
//            Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", isFavorite: true),
//            Quote(text: "Stay hungry, stay foolish.", author: "Steve Jobs", isFavorite: true),
//            Quote(text: "Be the change you wish to see in the world.", author: "Mahatma Gandhi", isFavorite: true)
//        ]
//
//        for quote in sampleQuotes {
//            context.insert(quote)
//        }
//
//        // Optionally, add a scheduled quote to test activeScheduledQuoteID
//        let scheduledQuote = ScheduledQuote(quoteID: sampleQuotes[0].id, duration: 7)
//        context.insert(scheduledQuote)
//
//        try! context.save()
//
//        return FavoritesView(selectedQuote: .constant(nil), showingDetail: .constant(false))
//            .modelContainer(container)
//    }
//}
