//  QuotesApp.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI
import SwiftData
import UserNotifications

@main
struct QuotesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Quote.self, ScheduledQuote.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Request notification permission
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if granted {
                            scheduleNotifications()
                        }
                    }
                    // Pre-populate static quotes
                    preloadStaticQuotes()
                }
        }
    }
    
    func preloadStaticQuotes() {
        let context = sharedModelContainer.mainContext
        let fetchRequest = FetchDescriptor<Quote>(predicate: #Predicate<Quote> { !$0.isCustom })
        do {
            let existingCount = try context.fetchCount(fetchRequest)
            if existingCount == 0 {
                // Initialize 10 static quotes
                let staticQuotes = [
                    Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", isCustom: false),
                    Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", isCustom: false),
                    Quote(text: "Stay hungry, stay foolish.", author: "Steve Jobs", isCustom: false, isFavorite: true),
                    Quote(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu", isCustom: false),
                    Quote(text: "Be the change you wish to see in the world.", author: "Mahatma Gandhi", isCustom: true),
                    Quote(text: "I have a dream.", author: "Martin Luther King Jr.", isCustom: false),
                    Quote(text: "To be or not to be, that is the question.", author: "William Shakespeare", isCustom: true),
                    Quote(text: "Imagination is more important than knowledge.", author: "Albert Einstein", isCustom: false),
                    Quote(text: "Do one thing every day that scares you.", author: "Eleanor Roosevelt", isCustom: false),
                    Quote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein", isCustom: false)
                ]
                for quote in staticQuotes {
                    context.insert(quote)
                }
                try context.save()
            }
        } catch {
            print("Error preloading quotes: \(error)")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Handle notification tap when app is terminated
        if let notification = launchOptions?[.remoteNotification] as? [String: Any],
           let quoteIDString = notification["quoteID"] as? String,
           let quoteID = UUID(uuidString: quoteIDString) {
            UserDefaults.standard.set(quoteIDString, forKey: "pendingQuoteID")
            NotificationCenter.default.post(name: NSNotification.Name("ShowQuote"), object: quoteID)
        }
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let quoteIDString = response.notification.request.content.userInfo["quoteID"] as? String,
           let quoteID = UUID(uuidString: quoteIDString) {
            UserDefaults.standard.set(quoteIDString, forKey: "pendingQuoteID")
            NotificationCenter.default.post(name: NSNotification.Name("ShowQuote"), object: quoteID)
        }
        completionHandler()
    }
}

func removeAllFixedQuoteNotifications() {
    let center = UNUserNotificationCenter.current()
    
    // Fetch all ScheduledQuotes to cancel their notifications
    let allScheduledFetch = FetchDescriptor<ScheduledQuote>()
    var allScheduledQuotes: [ScheduledQuote] = []
    do {
        allScheduledQuotes = try ModelContext(QuotesApp().sharedModelContainer).fetch(allScheduledFetch)
        for item in allScheduledQuotes {
            ModelContext(QuotesApp().sharedModelContainer).delete(item)
        }
    } catch {
        print("Error fetching all scheduled quotes for cancellation: \(error)")
        return
    }
    
    // Cancel existing notifications for all ScheduledQuotes
    let allQuoteIDs = allScheduledQuotes.map { $0.quoteID.uuidString }
    center.removePendingNotificationRequests(withIdentifiers: allQuoteIDs)
}

func scheduleScheduledQuoteNotifications() {
    
    removeAllFixedQuoteNotifications();
    let center = UNUserNotificationCenter.current()
    
    
    // Fetch active ScheduledQuotes
    let activeFetch = FetchDescriptor<ScheduledQuote>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
    )
    var activeScheduledQuotes: [ScheduledQuote] = []
    do {
        let allQuotes = try ModelContext(QuotesApp().sharedModelContainer).fetch(activeFetch)
        activeScheduledQuotes = allQuotes.filter { scheduled in
            let currentDate = Date()
            return currentDate >= scheduled.startDate &&
                   currentDate < Calendar.current.date(byAdding: .day, value: scheduled.duration, to: scheduled.startDate) ?? Date()
        }
    } catch {
        print("Error fetching scheduled quotes: \(error)")
        return
    }
    
    // Schedule one daily repeating notification for each active ScheduledQuote
    let calendar = Calendar.current
    for scheduled in activeScheduledQuotes {
        // Fetch the corresponding Quote
        let quoteID = scheduled.quoteID
        let quoteFetch = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { quote in
                quote.id == quoteID
            }
        )
        guard let quote = try? ModelContext(QuotesApp().sharedModelContainer).fetch(quoteFetch).first else {
            print("No quote found for quoteID: \(quoteID)")
            continue
        }
        
        // Extract hour and minute from notificationTime
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduled.notificationTime)
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Quote"
        content.body = quote.author != nil ? "\(quote.text) — \(quote.author!)" : quote.text
        content.sound = .default
        content.userInfo = ["quoteID": quote.id.uuidString]
        content.categoryIdentifier = "QUOTE_NOTIFICATION"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: quote.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification for quoteID \(quote.id): \(error)")
            } else {
                print("Scheduled daily notification for \(quote.text) at \(timeComponents.hour!):\(timeComponents.minute!)")
            }
        }
    }
}

func scheduleNotifications() {
    let center = UNUserNotificationCenter.current()
    
    // Fetch all ScheduledQuotes to get their quoteIDs
    let scheduledFetch = FetchDescriptor<ScheduledQuote>()
    var scheduledQuotes: [ScheduledQuote] = []
    do {
        scheduledQuotes = try ModelContext(QuotesApp().sharedModelContainer).fetch(scheduledFetch)
    } catch {
        print("Error fetching scheduled quotes for filtering: \(error)")
        // Proceed without filtering if fetch fails
    }
    
    // Get quoteIDs from ScheduledQuotes to exclude from cancellation
    let scheduledQuoteIDs = scheduledQuotes.map { $0.quoteID.uuidString }
    
    // Get all pending notification requests and filter out ScheduledQuote notifications
    center.getPendingNotificationRequests { requests in
        let nonScheduledQuoteIDs = requests
            .map { $0.identifier }
            .filter { !scheduledQuoteIDs.contains($0) }
        
        // Remove only non-ScheduledQuote notifications
        center.removePendingNotificationRequests(withIdentifiers: nonScheduledQuoteIDs)
        
        // Get notification times from UserDefaults (default: 10:50 AM)
        let defaults = UserDefaults.standard
        let notificationTimes = defaults.array(forKey: "notificationTimes") as? [[String: Int]] ?? [["hour": 10, "minute": 50]]
        
        let context = ModelContext(QuotesApp().sharedModelContainer)
        let quoteFetch = FetchDescriptor<Quote>()
        var allQuotes: [Quote] = []
        do {
            allQuotes = try context.fetch(quoteFetch)
        } catch {
            print("Error fetching quotes: \(error)")
            return
        }
        
        var cycle = defaults.array(forKey: "quoteCycle") as? [String] ?? []
        var index = defaults.integer(forKey: "nextQuoteIndex")
        
        if cycle.isEmpty || cycle.count != allQuotes.count {
            cycle = allQuotes.shuffled().map { $0.id.uuidString }
            index = 0
            defaults.set(cycle, forKey: "quoteCycle")
            defaults.set(index, forKey: "nextQuoteIndex")
        }
        
        // Schedule a notification for each time
        for time in notificationTimes {
            guard let hour = time["hour"], let minute = time["minute"] else { continue }
            
            guard let quoteID = cycle[safe: index],
                  let uuid = UUID(uuidString: quoteID),
                  let quote = allQuotes.first(where: { $0.id == uuid }) else { continue }
            
            index = (index + 1) % cycle.count
            defaults.set(index, forKey: "nextQuoteIndex")
            
            let content = UNMutableNotificationContent()
            content.title = "Daily Quote"
            content.body = quote.text
            content.userInfo = ["quoteID": quote.id.uuidString]
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
}


func scheduleNotificationsOG() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
    
    // Get notification times from UserDefaults (default: 10:50 AM)
    let defaults = UserDefaults.standard
    let notificationTimes = defaults.array(forKey: "notificationTimes") as? [[String: Int]] ?? [[ "hour": 10, "minute": 50 ]]
    
    let context = ModelContext(QuotesApp().sharedModelContainer)
    let quoteFetch = FetchDescriptor<Quote>()
    var allQuotes: [Quote] = []
    do {
        allQuotes = try context.fetch(quoteFetch)
    } catch {
        print("Error fetching quotes: \(error)")
        return
    }
    
    // Check for active ScheduledQuote
    let scheduledFetch = FetchDescriptor<ScheduledQuote>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
    var activeScheduledQuote: Quote? = nil
    do {
        if let scheduled = try context.fetch(scheduledFetch).first {
            let endDate = Calendar.current.date(byAdding: .day, value: scheduled.duration, to: scheduled.startDate) ?? Date()
            if Date() >= scheduled.startDate && Date() < endDate {
                let quoteID = scheduled.quoteID // Bind scheduled.quoteID to a local variable
                let quoteFetch = FetchDescriptor<Quote>(predicate: #Predicate<Quote> { quote in
                    quote.id == quoteID
                })
                activeScheduledQuote = try context.fetch(quoteFetch).first
            }
        }
    } catch {
        print("Error fetching scheduled quote: \(error)")
    }
    
    var cycle = defaults.array(forKey: "quoteCycle") as? [String] ?? []
    var index = defaults.integer(forKey: "nextQuoteIndex")
    
    if cycle.isEmpty || cycle.count != allQuotes.count {
        cycle = allQuotes.shuffled().map { $0.id.uuidString }
        index = 0
        defaults.set(cycle, forKey: "quoteCycle")
        defaults.set(index, forKey: "nextQuoteIndex")
    }
    
    // Schedule a notification for each time
    for time in notificationTimes {
        guard let hour = time["hour"], let minute = time["minute"] else { continue }
        
        let quote: Quote?
        if let scheduledQuote = activeScheduledQuote {
            quote = scheduledQuote
        } else {
            guard let quoteID = cycle[safe: index],
                  let uuid = UUID(uuidString: quoteID),
                  let regularQuote = allQuotes.first(where: { $0.id == uuid }) else { continue }
            quote = regularQuote
            index = (index + 1) % cycle.count
            defaults.set(index, forKey: "nextQuoteIndex")
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Quote"
        content.body = quote?.text ?? "Your daily quote"
        content.userInfo = ["quoteID": quote?.id.uuidString ?? ""]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// Safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

func getNextQuoteForNotification() -> Quote? {
    let context = ModelContext(QuotesApp().sharedModelContainer)
    let quoteFetch = FetchDescriptor<Quote>()
    do {
        let allQuotes = try context.fetch(quoteFetch)
        if allQuotes.isEmpty { return nil }
        
        let defaults = UserDefaults.standard
        var cycle = defaults.array(forKey: "quoteCycle") as? [String] ?? []
        var index = defaults.integer(forKey: "nextQuoteIndex")
        
        if cycle.isEmpty || cycle.count != allQuotes.count {
            cycle = allQuotes.shuffled().map { $0.id.uuidString }
            index = 0
            defaults.set(cycle, forKey: "quoteCycle")
            defaults.set(index, forKey: "nextQuoteIndex")
        }
        
        let scheduledFetch = FetchDescriptor<ScheduledQuote>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        if let scheduled = try? context.fetch(scheduledFetch).first {
            let endDate = Calendar.current.date(byAdding: .day, value: scheduled.duration, to: scheduled.startDate) ?? Date()
            if Date() >= scheduled.startDate && Date() < endDate {
                return allQuotes.first { $0.id == scheduled.quoteID }
            }
        }
        
        if let quoteID = UUID(uuidString: cycle[index]),
           let quote = allQuotes.first(where: { $0.id == quoteID }) {
            index = (index + 1) % cycle.count
            defaults.set(index, forKey: "nextQuoteIndex")
            return quote
        }
    } catch {
        print("Error fetching quotes: \(error)")
    }
    return nil
}
