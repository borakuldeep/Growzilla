//  HomeView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI

var defaultNotificationTimes: [[String: Int]] = [["hour": 16, "minute": 22]]

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var quotes: [Quote]
    @Binding var selectedQuote: Quote?
    //@Binding var showingDetail: Bool
    @Binding var showingSettings: Bool
    @Binding var notificationTimes: [[String: Int]]
    @State private var showCopiedToast = false

    @State private var notificationCount = 0  // State to store notification count

    let placeholderQuote = Quote(
        text: "Life is 10% what happens to us and 90% how we react to it"
    )

    // Use @State instead of @AppStorage for dictionary
    @State private var selectedCategories: [String: Bool] = [
        "Life Wisdom": false,
        "Health": false,
        "Motivational": false,
        "Wealth": false,
    ]

    // Function to save selectedCategories to UserDefaults
    private func saveSelectedCategories() {
        do {
            let data = try JSONEncoder().encode(selectedCategories)
            UserDefaults.standard.set(data, forKey: "selectedCategories")
        } catch {
            print("Error encoding selectedCategories: \(error)")
        }
    }

    // Function to load selectedCategories from UserDefaults
    private func loadSelectedCategories() {
        if let data = UserDefaults.standard.data(forKey: "selectedCategories") {
            do {
                let decoded = try JSONDecoder().decode(
                    [String: Bool].self,
                    from: data
                )
                selectedCategories = decoded
            } catch {
                print("Error decoding selectedCategories: \(error)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()  // Center quote vertically
                if notificationCount == 0 {
                    VStack(spacing: 30) {
                        // Welcome message
                        Text("Welcome to Yes You Can!")
                            .font(.title).padding(.top, 30)
                        Text(
                            "We believe words have power to change minds and the world itself."
                        )
                        .font(.callout)
                        .padding(.trailing)
                        Text(
                            "We hope these quotes will motivate you to become better everyday."
                        )
                        .font(.callout)
                        .padding(.trailing)
                        Text("Please choose one or more categories to start.")
                            .font(.callout)
                            .padding(.trailing)

                        // List with custom padding
                        List {
                            ForEach(
                                selectedCategories.keys.sorted(),
                                id: \.self
                            ) { category in
                                Toggle(
                                    category,
                                    isOn: Binding(
                                        get: {
                                            selectedCategories[category]
                                                ?? false
                                        },
                                        set: { newValue in
                                            selectedCategories[category] =
                                                newValue
                                            saveSelectedCategories()  // Save on change
                                        }
                                    )
                                )
                                .toggleStyle(CheckToggleStyle())
                            }
                        }
                        .scrollContentBackground(.hidden)
                        //.padding(.horizontal, 16) // Explicit padding to match text
                        //.background(Color.gray.opacity(0.1)) // Optional: to visualize bounds

                        // Button with consistent padding
                        Button("All Done") {
                            Task {
                                let userSelected = selectedCategories.filter {
                                    $0.value
                                }
                                .map { $0.key }
                                print("userSelected: \(userSelected)")
                                processQuotes(
                                    for: userSelected,
                                    in: modelContext
                                )
                                notificationTimes =
                                    defaultNotificationTimes
                                UserDefaults.standard.set(
                                    notificationTimes,
                                    forKey: "notificationTimes"
                                )
                                scheduleNotifications()
                                notificationCount = await getNotificationCount()
                                print("Button tapped!")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .disabled(!selectedCategories.values.contains(true))
                        .padding(.horizontal, 16)  // Match List padding
                    }
                    .padding(.horizontal, 16)  // Outer padding for the entire VStack

                } else if let quote = selectedQuote {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(quote.text)
                            .font(.title2)
                            .padding(.horizontal)
                        Text(quote.author ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        if selectedQuote?.text == placeholderQuote.text {
                            Text(
                                "This is a placeholder quote until you get from earlist schedule notification."
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        }
                        
                        if selectedQuote?.text == placeholderQuote.text {
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
                        }
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
            .gradientBackground()
            //.navigationTitle("Yes You Can")
            .toolbar {
                if notificationCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundStyle(colorScheme == .dark ? .white : .blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    notificationTimes: $notificationTimes,
                    showingSettings: $showingSettings
                )
            }
            .task {
                notificationCount = await getNotificationCount()
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
                            selectedQuote = placeholderQuote  //quotes.randomElement()
                        }
                    } catch {
                        print("Error fetching quote by ID: \(error)")
                        selectedQuote = placeholderQuote  //quotes.randomElement()
                    }
                } else {
                    selectedQuote = placeholderQuote  //quotes.randomElement()
                }
                print("on appear called")
                // Reload notification times and reschedule
                notificationTimes =
                    UserDefaults.standard.array(forKey: "notificationTimes")
                    as? [[String: Int]] ?? defaultNotificationTimes
                //scheduleNotifications()
                //print(notificationTimes)
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
                        selectedQuote = placeholderQuote  //quotes.randomElement()
                    }
                }
            }

        }
    }
}

#Preview {
    HomeView(
        selectedQuote: .constant(nil),
        showingSettings: .constant(false),
        notificationTimes: .constant([])
    )
    .modelContainer(for: Quote.self, inMemory: true)
}
