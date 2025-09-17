//
//  ScheduleSheet.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/8/25.
//

//  ScheduleSheet.swift
//  Quotes
//
//  Created by Grok on 9/8/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftData
import SwiftUI
import UserNotifications

struct ScheduleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Binding var schedulingQuote: Quote?
    @Binding var showingScheduleSheet: Bool
    let options = [
        "1 week": 7, "2 weeks": 14, "3 weeks": 21, "4 weeks": 28, "1 month": 30,
        "3 months": 90,
    ]
    @State private var selectedDuration: Int = 7
    @State private var isQuoteScheduled: Bool = false  // Track if quote is scheduled
    @State private var notificationTime: Date =
        Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()  // Default to 9:00 AM
    @State private var errorMessage: String?
    @State private var initialNotificationTime: Date?

    // Fetch to check if the quote is already scheduled
    private func checkIfQuoteIsScheduled(quoteID: UUID) -> Bool {
        let quoteID = quoteID
        let fetchDescriptor = FetchDescriptor<ScheduledQuote>(
            predicate: #Predicate<ScheduledQuote> { scheduled in
                scheduled.quoteID == quoteID
            }
        )
        do {
            let scheduledQuotes = try modelContext.fetch(fetchDescriptor)
            return !scheduledQuotes.isEmpty
        } catch {
            print("Error checking scheduled quote: \(error)")
            return false
        }
    }

    var body: some View {
        if let quote = schedulingQuote {

            NavigationStack {
                Form {
                    Section(header: Text("Quote")) {
                        VStack(alignment: .leading) {
                            Text(quote.text)
                            if let author = quote.author {
                                Text(author).font(.subheadline)
                            }
                        }
                    }
                    Section(header: Text("Select duration")) {
                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(options.keys.sorted(), id: \.self) { key in
                                Text(key).tag(options[key]!)
                            }
                        }
                    }
                    Section(header: Text("Select time")) {
                        DatePicker(
                            "At Daily",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                    if isQuoteScheduled {  // Conditionally show the "Remove from schedule" button
                        Section {
                            Button("Remove from schedule") {
                                let quoteID = quote.id
                                let fetchDescriptor = FetchDescriptor<
                                    ScheduledQuote
                                >(
                                    predicate: #Predicate<ScheduledQuote> {
                                        scheduled in
                                        scheduled.quoteID == quoteID
                                    }
                                )
                                do {
                                    let scheduledQuotes =
                                        try modelContext.fetch(fetchDescriptor)
                                    for scheduled in scheduledQuotes {
                                        modelContext.delete(scheduled)
                                        // Remove notification
                                        UNUserNotificationCenter.current()
                                            .removePendingNotificationRequests(
                                                withIdentifiers: [
                                                    quote.id.uuidString
                                                ])
                                    }
                                    try modelContext.save()
                                    showingScheduleSheet = false
                                } catch {
                                    print(
                                        "Error removing scheduled quote: \(error)"
                                    )
                                }
                            }.foregroundStyle(Color.red)
                        }
                    }
                    Text("NOTE: Only one fixed quote can be scheduled at a time")
                        .font(.subheadline).foregroundColor(.red)

//                    if !isQuoteScheduled {
//                        Section {
//                            Text(
//                                "Scheduling this quote will remove any existing fixed quotes"
//                            ).font(.subheadline).foregroundColor(.red)
//                        }
//                    }
                }
                .gradientBackground()
                .navigationTitle("Schedule Quote")
                //.background(.clear)
                .scrollContentBackground(.hidden)
                //colorScheme == .dark ? .white : .black
//                .background(
//                    colorScheme == .dark
//                        ? Color(hex: "#454545") : Color(hex: "#FFFAF5")
//                )
                //.scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingScheduleSheet = false
                        }.foregroundStyle(colorScheme == .dark ? .white : .blue)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schedule") {

                            let allScheduledFetch = FetchDescriptor<
                                ScheduledQuote
                            >()
                            if let allScheduledQuotes = try? modelContext.fetch(
                                allScheduledFetch
                            ) {
                                for item in allScheduledQuotes {
                                    modelContext.delete(item)
                                }
                            }

                            // Insert new scheduled quote with notification time
                            let scheduled = ScheduledQuote(
                                quoteID: quote.id,
                                duration: selectedDuration,
                                notificationTime: notificationTime
                            )
                            modelContext.insert(scheduled)
                            try? modelContext.save()
                            scheduleScheduledQuoteNotifications(
                                quoteToSchedule: scheduled
                            )
                            showingScheduleSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .disabled(
                            isQuoteScheduled
                                && notificationTime == initialNotificationTime
                        )
                    }
                }
                .onAppear {
                    isQuoteScheduled = checkIfQuoteIsScheduled(
                        quoteID: quote.id
                    )
                    // Load existing notification time if scheduled
                    if isQuoteScheduled {
                        let searchId = quote.id
                        let fetchDescriptor = FetchDescriptor<ScheduledQuote>(
                            predicate: #Predicate<ScheduledQuote> {
                                $0.quoteID == searchId
                            }
                        )
                        if let existing = try? modelContext.fetch(
                            fetchDescriptor
                        ).first {
                            notificationTime = existing.notificationTime
                            initialNotificationTime = existing.notificationTime
                        }
                    } else {
                        initialNotificationTime = notificationTime  // Set to default if not scheduled
                    }
                }

            }

        }
    }

}

#Preview {
    ScheduleSheet(
        schedulingQuote: .constant(Quote(text: "Sample quote", isCustom: true)),
        showingScheduleSheet: .constant(true)
    )
    .modelContainer(for: [Quote.self, ScheduledQuote.self], inMemory: true)
}
