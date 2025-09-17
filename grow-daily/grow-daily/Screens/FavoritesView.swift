// FavoritesView.swift
// Quotes
//
// Created by Grok on 9/7/2025.
// Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query(filter: #Predicate<Quote> { $0.isFavorite }) private var favoriteQuotes: [Quote]
    @Query(sort: \ScheduledQuote.startDate, order: .reverse) private var scheduledQuotes: [ScheduledQuote]
    @Binding var showingDetail: Bool
    @State private var showingScheduleSheet = false
    @State private var schedulingQuote: Quote?
    @State private var searchText = "" // Added state for search text
    var localQuotes = [] as [Quote]
    
    var activeScheduledQuoteID: UUID? {
        if let scheduled = scheduledQuotes.first {
            let endDate = Calendar.current.date(
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
    
    // Computed property to filter quotes based on search text
    var filteredQuotes: [Quote] {
        let allQuotes = favoriteQuotes + localQuotes
        if searchText.isEmpty {
            return allQuotes
        } else {
            return allQuotes.filter { quote in
                quote.text.lowercased().contains(searchText.lowercased()) ||
                (quote.author?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
            NavigationView {
                ZStack {
//                    Image("zenBg")
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(minWidth: 0, maxWidth: .infinity)
//                        .edgesIgnoringSafeArea(.all)
//                        .opacity(0.5)
//                    if colorScheme == .light {
//                        bgGradient
//                            .ignoresSafeArea()
//                    }
//                    else {
//                        bgDark
//                            .ignoresSafeArea()
//                    }
                        
                        List {
                            Section() {
                                if filteredQuotes.isEmpty {
                                    Text("No matching favorite quotes")
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(filteredQuotes) { quote in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(quote.text)
                                                if let author = quote.author {
                                                    Text(author).font(.subheadline)
                                                }
                                            }
                                            .padding(2)
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Button(action: {
                                                    schedulingQuote = quote
                                                    showingScheduleSheet = true
                                                }) {
                                                    Image(
                                                        systemName: quote.id == activeScheduledQuoteID
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
                                                    Text("scheduled").font(.subheadline)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }
                                        .swipeActions {
                                            Button {
                                                if quote.id != activeScheduledQuoteID {
                                                    quote.isFavorite.toggle()
                                                    try? modelContext.save()
                                                }
                                            } label: {
                                                if quote.id == activeScheduledQuoteID {
                                                    Text("Unschedule to unfavorite")
                                                        .font(.subheadline)
                                                } else {
                                                    Label(
                                                        "Unfavorite",
                                                        systemImage: "heart.slash"
                                                    )
                                                }
                                            }
                                            .tint(
                                                quote.id != activeScheduledQuoteID
                                                ? .pink : .gray
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        //.padding(.top, 45)
                        .scrollContentBackground(.hidden)
                        //.background(.clear)
//                        .background(
//                            colorScheme == .dark
//                                ? Color(hex: "#454545") : Color(hex: "#FFFAF5")
//                        )
                        .navigationTitle("Favorites")
                        .searchable(text: $searchText, prompt: "Search quotes or authors").disabled(favoriteQuotes.isEmpty)
                        .sheet(isPresented: $showingScheduleSheet) {
                            ScheduleSheet(
                                schedulingQuote: $schedulingQuote,
                                showingScheduleSheet: $showingScheduleSheet
                            )
                        }
                        if favoriteQuotes.isEmpty {
                            VStack {
                                Spacer()
                                Text(
                                    "You can schedule any of your favorite quote for daily notification from here."
                                ).font(.title3).padding()
                                Spacer()
                            }.padding(.horizontal)
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
            isFavorite: true
        ),
        Quote(
            text: "Be the change you wish to see in the world.",
            author: "Mahatma Gandhi",
            isFavorite: true
        ),
    ]
    FavoritesView(
        showingDetail: .constant(false),
        localQuotes: sampleQuotes
    )
    .modelContainer(for: [Quote.self, ScheduledQuote.self], inMemory: true)
}
