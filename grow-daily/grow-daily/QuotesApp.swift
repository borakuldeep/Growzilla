//  QuotesApp.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI
import UserNotifications

class AppState: ObservableObject {
    @Published var hasLaunched = false
}

@main
struct QuotesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Quote.self, ScheduledQuote.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
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
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge]) {
                            granted,
                            error in
//                            if granted {
//                                scheduleNotifications()
//                            }
                        }
                    // Pre-populate static quotes
                    //preloadStaticQuotes()

                    if !appState.hasLaunched {
                        //scheduleNotifications()
                        removeAllDeliveredNotificationsbutLast()
                        appState.hasLaunched = true
                    }
                }
                .onChange(of: scenePhase) { newPhase, _ in
                    if newPhase == .active && !appState.hasLaunched {
                        //scheduleNotifications()
                        removeAllDeliveredNotificationsbutLast()
                        appState.hasLaunched = true
                    }
                }

        }
    }

//    func preloadStaticQuotes() {
//        let context = sharedModelContainer.mainContext
//        let fetchRequest = FetchDescriptor<Quote>(
//            predicate: #Predicate<Quote> { !$0.isCustom }
//        )
//        do {
//            let existingCount = try context.fetchCount(fetchRequest)
//            if existingCount == 0 {
//                // Initialize 10 static quotes
//                let staticQuotes = [
//                    Quote(
//                        text:
//                            "The only way to do great work is to love what you do.",
//                        author: "Steve Jobs",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text:
//                            "Life is what happens when you're busy making other plans.",
//                        author: "John Lennon",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text: "Stay hungry, stay foolish.",
//                        author: "Steve Jobs",
//                        isCustom: false,
//                        isFavorite: true
//                    ),
//                    Quote(
//                        text:
//                            "The journey of a thousand miles begins with one step.",
//                        author: "Lao Tzu",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text: "Be the change you wish to see in the world.",
//                        author: "Mahatma Gandhi",
//                        isCustom: true
//                    ),
//                    Quote(
//                        text: "I have a dream.",
//                        author: "Martin Luther King Jr.",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text: "To be or not to be, that is the question.",
//                        author: "William Shakespeare",
//                        isCustom: true
//                    ),
//                    Quote(
//                        text: "Imagination is more important than knowledge.",
//                        author: "Albert Einstein",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text: "Do one thing every day that scares you.",
//                        author: "Eleanor Roosevelt",
//                        isCustom: false
//                    ),
//                    Quote(
//                        text: "In the middle of difficulty lies opportunity.",
//                        author: "Albert Einstein",
//                        isCustom: false
//                    ),
//                ]
//                for quote in staticQuotes {
//                    context.insert(quote)
//                }
//                try context.save()
//            }
//        } catch {
//            print("Error preloading quotes: \(error)")
//        }
//    }
}

class AppDelegate: NSObject, UIApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Handle notification tap when app is terminated
        if let notification = launchOptions?[.remoteNotification]
            as? [String: Any],
            let quoteIDString = notification["quoteID"] as? String,
            let quoteID = UUID(uuidString: quoteIDString)
        {
            UserDefaults.standard.set(quoteIDString, forKey: "pendingQuoteID")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowQuote"),
                object: quoteID
            )
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let quoteIDString = response.notification.request.content.userInfo[
            "quoteID"
        ] as? String,
            let quoteID = UUID(uuidString: quoteIDString)
        {
            UserDefaults.standard.set(quoteIDString, forKey: "pendingQuoteID")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowQuote"),
                object: quoteID
            )
        }
        completionHandler()
    }
}
