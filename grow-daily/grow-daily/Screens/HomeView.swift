//  HomeView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var quotes: [Quote]
    @Binding var selectedQuote: Quote?
    @Binding var showingDetail: Bool
    @Binding var showingSettings: Bool
    @Binding var notificationTimes: [[String: Int]]
    @State private var showCopiedToast = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()  // Center quote vertically
                if let quote = selectedQuote {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(quote.text)
                            .font(.title2)
                            .padding(.horizontal)
                        if let author = quote.author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        HStack(spacing: 20) {
                            Spacer()
                            Button(action: {
                                quote.isFavorite.toggle()
                                try? modelContext.save()
                            }) {
                                Image(
                                    systemName: quote.isFavorite
                                        ? "heart.fill" : "heart"
                                )
                                .font(.title)
                                .foregroundColor(
                                    quote.isFavorite ? .pink : .gray
                                )
                            }
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = quote.text
                                showCopiedToast = true
                                DispatchQueue.main.asyncAfter(
                                    deadline: .now() + 2
                                ) {
                                    showCopiedToast = false
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        // Toast view
                        if showCopiedToast {
                            HStack {
                                Spacer()
                                Text("Quote copied!")
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )
                                    .transition(.opacity)
                                    .zIndex(1)
                                Spacer()
                            }
                            .padding(.bottom)
                        }
                    }
                    .animation(.easeInOut, value: showCopiedToast)
                } else {
                    Text("No quote selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()  // Center quote vertically
            }
            .navigationTitle("Daily Quote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    notificationTimes: $notificationTimes,
                    showingSettings: $showingSettings
                )
            }
            .sheet(isPresented: $showingDetail) {
                if let quote = selectedQuote {
                    QuoteDetailView(quote: quote)
                }
            }
            .onAppear {
                // Prioritize last notification's quote
                if let quoteIDString = UserDefaults.standard.string(
                    forKey: "pendingQuoteID"
                ),
                    let quoteID = UUID(uuidString: quoteIDString)
                {
                    let fetchRequest = FetchDescriptor<Quote>(
                        predicate: #Predicate<Quote> { $0.id == quoteID }
                    )
                    do {
                        if let quote = try modelContext.fetch(fetchRequest)
                            .first
                        {
                            selectedQuote = quote
                        } else {
                            selectedQuote = quotes.randomElement()
                        }
                    } catch {
                        print("Error fetching quote by ID: \(error)")
                        selectedQuote = quotes.randomElement()
                    }
                } else {
                    selectedQuote = quotes.randomElement()
                }
                // Reload notification times and reschedule
                notificationTimes =
                    UserDefaults.standard.array(forKey: "notificationTimes")
                    as? [[String: Int]] ?? [["hour": 10, "minute": 50]]
                scheduleNotifications()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSNotification.Name("ShowQuote")
                )
            ) { notification in
                if let quoteID = notification.object as? UUID {
                    // Fetch quote directly from SwiftData using ID
                    let fetchRequest = FetchDescriptor<Quote>(
                        predicate: #Predicate<Quote> { $0.id == quoteID }
                    )
                    do {
                        if let quote = try modelContext.fetch(fetchRequest)
                            .first
                        {
                            selectedQuote = quote
                        }
                    } catch {
                        print("Error fetching quote by ID: \(error)")
                        selectedQuote = quotes.randomElement()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(
        selectedQuote: .constant(nil),
        showingDetail: .constant(false),
        showingSettings: .constant(false),
        notificationTimes: .constant([])
    )
    .modelContainer(for: Quote.self, inMemory: true)
}
