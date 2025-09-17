//
//  NotificationUtils.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/11/25.
//

import SwiftData
import UserNotifications

func getNotificationCount() async -> Int {
    let center = UNUserNotificationCenter.current()
    let requests = await center.pendingNotificationRequests()
    //center.removeAllPendingNotificationRequests()

    let count = requests.count
    print("Scheduled notifications: \(count)")
    return count
}

func removeAllFixedQuoteNotifications() {
    let center = UNUserNotificationCenter.current()

    // Fetch all ScheduledQuotes to cancel their notifications
    let allScheduledFetch = FetchDescriptor<ScheduledQuote>()
    var allScheduledQuotes: [ScheduledQuote] = []

    do {
        let context = ModelContext(QuotesApp().sharedModelContainer)
        allScheduledQuotes = try context.fetch(allScheduledFetch)
        // Cancel existing notifications for all ScheduledQuotes
        let allQuoteIDs = allScheduledQuotes.map { $0.quoteID.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: allQuoteIDs)
        //delete all from storage
        //        for item in allScheduledQuotes {
        //            context.delete(item)
        //        }
        //        try context.save()
    } catch {
        print("Error fetching all scheduled quotes for cancellation: \(error)")
        return
    }

    print(
        "all notifications removed, allScheduledQuotes: \(allScheduledQuotes)"
    )
}

func scheduleScheduledQuoteNotifications(quoteToSchedule: ScheduledQuote) {

    removeAllFixedQuoteNotifications()
    let center = UNUserNotificationCenter.current()

    // Fetch active ScheduledQuotes
    let activeFetch = FetchDescriptor<ScheduledQuote>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
    )
    var activeScheduledQuotes: [ScheduledQuote] = []
    let context = ModelContext(QuotesApp().sharedModelContainer)
    do {
        context.insert(quoteToSchedule)
        try context.save()
        let allQuotes = try context.fetch(activeFetch)
        activeScheduledQuotes = allQuotes.filter { scheduled in
            let currentDate = Date()
            return currentDate >= scheduled.startDate
                && currentDate < Calendar.current.date(
                    byAdding: .day,
                    value: scheduled.duration,
                    to: scheduled.startDate
                ) ?? Date()
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
        guard
            let quote = try? context.fetch(quoteFetch).first
        else {
            print("No quote found for quoteID: \(quoteID)")
            continue
        }

        // Extract hour and minute from notificationTime
        let timeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: scheduled.notificationTime
        )

        let content = UNMutableNotificationContent()
        content.title = "Daily Quote"
        content.body =
            quote.author != nil
            ? "\(quote.text) — \(quote.author!)" : quote.text
        content.sound = .default
        content.userInfo = ["quoteID": quote.id.uuidString]
        content.categoryIdentifier = "QUOTE_NOTIFICATION"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: timeComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: quote.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print(
                    "Error scheduling notification for quoteID \(quote.id): \(error)"
                )
            } else {
                print(
                    "Scheduled daily notification for \(quote.text) at \(timeComponents.hour!):\(timeComponents.minute!)"
                )
            }
        }
    }
}

func removeAllDeliveredNotificationsbutLast() {
    let center = UNUserNotificationCenter.current()

    // Remove all but last delivered notifications
    center.getDeliveredNotifications { notifications in
        // Only proceed with removal if there is more than one delivered notification
        if notifications.count > 1 {
            // Sort notifications by date (most recent first)
            let sortedNotifications = notifications.sorted { $0.date > $1.date }

            // Keep the most recent notification and remove the rest
            let notificationsToRemove = sortedNotifications.dropFirst().map {
                $0.request.identifier
            }
            center.removeDeliveredNotifications(
                withIdentifiers: notificationsToRemove
            )
        } else {
            print("Only one or no delivered notifications, keeping it")
        }
    }
}

func scheduleNotifications() {
    let center = UNUserNotificationCenter.current()

    // Get notification times from UserDefaults (default: 8:00 AM)
    let defaults = UserDefaults.standard
    var notificationTimes =
    defaults.array(forKey: "notificationTimes") as? [[String: Int]] ?? defaultNotificationTimes
    
    notificationTimes = notificationTimes.isEmpty ? defaultNotificationTimes : notificationTimes
    print("notificationTimes: ")
    print(notificationTimes)

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
        guard let hour = time["hour"], let minute = time["minute"] else {
            continue
        }

        guard let quoteID = cycle[safe: index],
            let uuid = UUID(uuidString: quoteID),
            let quote = allQuotes.first(where: { $0.id == uuid })
        else { continue }

        index = (index + 1) % cycle.count
        defaults.set(index, forKey: "nextQuoteIndex")

        let content = UNMutableNotificationContent()
        content.title = "Daily Quote"
        content.body = quote.text
        content.userInfo = ["quoteID": quote.id.uuidString]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

func removeAllNonFixedQuoteNotifications() {
    let center = UNUserNotificationCenter.current()
    
    // Fetch all ScheduledQuotes to get their quoteIDs
    let scheduledFetch = FetchDescriptor<ScheduledQuote>()
    var scheduledQuotes: [ScheduledQuote] = []
    do {
        scheduledQuotes = try ModelContext(QuotesApp().sharedModelContainer)
            .fetch(scheduledFetch)
    } catch {
        print("Error fetching scheduled quotes for filtering: \(error)")
        // Proceed without filtering if fetch fails
    }

    // Get quoteIDs from ScheduledQuotes to exclude from cancellation
    let scheduledQuoteIDs = scheduledQuotes.map { $0.quoteID.uuidString }

    // Get all pending notification requests and filter out ScheduledQuote notifications
    center.getPendingNotificationRequests { requests in
        let nonScheduledQuoteIDs =
        requests
            .map { $0.identifier }
            .filter { !scheduledQuoteIDs.contains($0) }
        
        // Remove only non-FixedScheduledQuote notifications
        center.removePendingNotificationRequests(
            withIdentifiers: nonScheduledQuoteIDs
        )
    }
}

func scheduleNotifications_lastUsed_Sept13() {
    let center = UNUserNotificationCenter.current()

    // Remove all but last delivered notifications
    center.getDeliveredNotifications { notifications in
        // Only proceed with removal if there is more than one delivered notification
        if notifications.count > 1 {
            // Sort notifications by date (most recent first)
            let sortedNotifications = notifications.sorted { $0.date > $1.date }

            // Keep the most recent notification and remove the rest
            let notificationsToRemove = sortedNotifications.dropFirst().map {
                $0.request.identifier
            }
            center.removeDeliveredNotifications(
                withIdentifiers: notificationsToRemove
            )
        } else {
            print("Only one or no delivered notifications, keeping it")
        }
    }

    // Fetch all ScheduledQuotes to get their quoteIDs
    let scheduledFetch = FetchDescriptor<ScheduledQuote>()
    var scheduledQuotes: [ScheduledQuote] = []
    do {
        scheduledQuotes = try ModelContext(QuotesApp().sharedModelContainer)
            .fetch(scheduledFetch)
    } catch {
        print("Error fetching scheduled quotes for filtering: \(error)")
        // Proceed without filtering if fetch fails
    }

    // Get quoteIDs from ScheduledQuotes to exclude from cancellation
    let scheduledQuoteIDs = scheduledQuotes.map { $0.quoteID.uuidString }

    // Get all pending notification requests and filter out ScheduledQuote notifications
    center.getPendingNotificationRequests { requests in
        let nonScheduledQuoteIDs =
            requests
            .map { $0.identifier }
            .filter { !scheduledQuoteIDs.contains($0) }

        // Remove only non-ScheduledQuote notifications
        center.removePendingNotificationRequests(
            withIdentifiers: nonScheduledQuoteIDs
        )

        // Get notification times from UserDefaults (default: 10:50 AM)
        let defaults = UserDefaults.standard
        let notificationTimes =
            defaults.array(forKey: "notificationTimes") as? [[String: Int]] ?? [
                ["hour": 08, "minute": 00]
            ]

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
            guard let hour = time["hour"], let minute = time["minute"] else {
                continue
            }

            guard let quoteID = cycle[safe: index],
                let uuid = UUID(uuidString: quoteID),
                let quote = allQuotes.first(where: { $0.id == uuid })
            else { continue }

            index = (index + 1) % cycle.count
            defaults.set(index, forKey: "nextQuoteIndex")

            let content = UNMutableNotificationContent()
            content.title = "Daily Quote"
            content.body = quote.text
            content.userInfo = ["quoteID": quote.id.uuidString]

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
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
    let notificationTimes =
        defaults.array(forKey: "notificationTimes") as? [[String: Int]] ?? [
            ["hour": 10, "minute": 50]
        ]

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
    let scheduledFetch = FetchDescriptor<ScheduledQuote>(sortBy: [
        SortDescriptor(\.startDate, order: .reverse)
    ])
    var activeScheduledQuote: Quote? = nil
    do {
        if let scheduled = try context.fetch(scheduledFetch).first {
            let endDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: scheduled.duration,
                    to: scheduled.startDate
                ) ?? Date()
            if Date() >= scheduled.startDate && Date() < endDate {
                let quoteID = scheduled.quoteID  // Bind scheduled.quoteID to a local variable
                let quoteFetch = FetchDescriptor<Quote>(
                    predicate: #Predicate<Quote> { quote in
                        quote.id == quoteID
                    }
                )
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
        guard let hour = time["hour"], let minute = time["minute"] else {
            continue
        }

        let quote: Quote?
        if let scheduledQuote = activeScheduledQuote {
            quote = scheduledQuote
        } else {
            guard let quoteID = cycle[safe: index],
                let uuid = UUID(uuidString: quoteID),
                let regularQuote = allQuotes.first(where: { $0.id == uuid })
            else { continue }
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
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
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

        let scheduledFetch = FetchDescriptor<ScheduledQuote>(sortBy: [
            SortDescriptor(\.startDate, order: .reverse)
        ])
        if let scheduled = try? context.fetch(scheduledFetch).first {
            let endDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: scheduled.duration,
                    to: scheduled.startDate
                ) ?? Date()
            if Date() >= scheduled.startDate && Date() < endDate {
                return allQuotes.first { $0.id == scheduled.quoteID }
            }
        }

        if let quoteID = UUID(uuidString: cycle[index]),
            let quote = allQuotes.first(where: { $0.id == quoteID })
        {
            index = (index + 1) % cycle.count
            defaults.set(index, forKey: "nextQuoteIndex")
            return quote
        }
    } catch {
        print("Error fetching quotes: \(error)")
    }
    return nil
}

