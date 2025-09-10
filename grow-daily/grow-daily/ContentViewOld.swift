//
//  ContentView.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//

import SwiftUI
import SwiftData

struct ContentViewOld: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var quotes: [Quote]
    @State private var selectedQuote: Quote?
    @State private var showingDetail = false
    @State private var showingSettings = false
    @State private var notificationTimes: [[String: Int]] = []
    
    var body: some View {
        TabView {
            // Home Tab: Show single quote (from notification or random)
            NavigationStack {
                VStack {
                    Spacer() // Center quote vertically
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
                            Button(action: {
                                quote.isFavorite.toggle()
                                try? modelContext.save()
                            }) {
                                Image(systemName: quote.isFavorite ? "heart.fill" : "heart")
                                    .font(.title)
                                    .foregroundColor(quote.isFavorite ? .pink : .gray)
                            }
                            .padding()
                        }
                    } else {
                        Text("No quote selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    Spacer() // Center quote vertically
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
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            selectedQuote = quotes.randomElement()
                            UserDefaults.standard.removeObject(forKey: "pendingQuoteID")
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(notificationTimes: $notificationTimes, showingSettings: $showingSettings)
                }
                .sheet(isPresented: $showingDetail) {
                    if let quote = selectedQuote {
                        QuoteDetailView(quote: quote)
                    }
                }
                .onAppear {
                    // Prioritize last notification's quote
                    if let quoteIDString = UserDefaults.standard.string(forKey: "pendingQuoteID"),
                       let quoteID = UUID(uuidString: quoteIDString) {
                        let fetchRequest = FetchDescriptor<Quote>(predicate: #Predicate<Quote> { $0.id == quoteID })
                        do {
                            if let quote = try modelContext.fetch(fetchRequest).first {
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
                    notificationTimes = UserDefaults.standard.array(forKey: "notificationTimes") as? [[String: Int]] ?? [[ "hour": 10, "minute": 50 ]]
                    scheduleNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowQuote"))) { notification in
                    if let quoteID = notification.object as? UUID {
                        // Fetch quote directly from SwiftData using ID
                        let fetchRequest = FetchDescriptor<Quote>(predicate: #Predicate<Quote> { $0.id == quoteID })
                        do {
                            if let quote = try modelContext.fetch(fetchRequest).first {
                                selectedQuote = quote
                            }
                        } catch {
                            print("Error fetching quote by ID: \(error)")
                            selectedQuote = quotes.randomElement()
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            // Favorites Tab
            NavigationStack {
                List {
                    Section("Favorite Quotes") {
                        let favoriteQuotes = quotes.filter { $0.isFavorite }
                        if favoriteQuotes.isEmpty {
                            Text("No favorite quotes yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(favoriteQuotes) { quote in
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
                                        Label("Unfavorite", systemImage: "heart.slash")
                                    }
                                    .tint(.pink)
                                }
                                .onTapGesture {
                                    selectedQuote = quote
                                    showingDetail = true
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Favorites")
                .sheet(isPresented: $showingDetail) {
                    if let quote = selectedQuote {
                        QuoteDetailView(quote: quote)
                    }
                }
            }
            .tabItem {
                Label("Favorites", systemImage: "heart")
            }
            
            // Custom Quotes Tab
            NavigationStack {
                List {
                    Section("Custom Quotes") {
                        let customQuotes = quotes.filter { $0.isCustom }
                        if customQuotes.isEmpty {
                            Text("No custom quotes yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(customQuotes) { quote in
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
                                        Label("Favorite", systemImage: quote.isFavorite ? "heart.fill" : "heart")
                                    }
                                    .tint(.pink)
                                    
                                    Button(role: .destructive) {
                                        modelContext.delete(quote)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture {
                                    selectedQuote = quote
                                    showingDetail = true
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Custom Quotes")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            let newQuote = Quote(text: "New quote", isCustom: true)
                            modelContext.insert(newQuote)
                            selectedQuote = newQuote
                            showingDetail = true
                        }
                    }
                }
                .sheet(isPresented: $showingDetail) {
                    if let quote = selectedQuote {
                        QuoteDetailView(quote: quote)
                    }
                }
            }
            .tabItem {
                Label("Custom", systemImage: "pencil")
            }
        }
    }
}

struct QuoteDetailViewOld: View {
    @Bindable var quote: Quote
    
    var body: some View {
        Form {
            TextField("Text", text: $quote.text)
            //TextField("Author", text: Binding($quote.author, replacingNilWith: ""))
            Toggle("Favorite", isOn: $quote.isFavorite)
        }
        .navigationTitle("Quote Detail")
    }
}

struct SettingsViewOld: View {
    @Binding var notificationTimes: [[String: Int]]
    @Binding var showingSettings: Bool
    @State private var newTime = Calendar.current.date(from: DateComponents(hour: 10, minute: 50))!
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notification Times") {
                    if notificationTimes.isEmpty {
                        Text("No notification times set")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(notificationTimes.indices, id: \.self) { index in
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: {
                                        let time = notificationTimes[index]
                                        return Calendar.current.date(from: DateComponents(hour: time["hour"], minute: time["minute"]))!
                                    },
                                    set: { newValue in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                        notificationTimes[index] = ["hour": components.hour!, "minute": components.minute!]
                                        saveAndReschedule()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        .onDelete { indices in
                            notificationTimes.remove(atOffsets: indices)
                            saveAndReschedule()
                        }
                    }
                }
                Section {
                    DatePicker(
                        "New Time",
                        selection: $newTime,
                        displayedComponents: .hourAndMinute
                    )
                    Button("Add Time") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                        notificationTimes.append(["hour": components.hour!, "minute": components.minute!])
                        newTime = Calendar.current.date(from: DateComponents(hour: 10, minute: 50))!
                        saveAndReschedule()
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveAndReschedule()
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    private func saveAndReschedule() {
        UserDefaults.standard.set(notificationTimes, forKey: "notificationTimes")
        scheduleNotifications()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Quote.self, inMemory: true)
}
