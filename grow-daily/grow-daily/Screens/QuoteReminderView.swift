//
//  QuoteReminderView.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//


//  QuoteReminderView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI
import SwiftData

struct QuoteReminderView: View {
    @Environment(\.modelContext) private var modelContext
    let quote: Quote
    @Binding var showingReminderSheet: Bool
    @State private var selectedOption: String = "1 week"
    private let reminderOptions = ["1 week", "2 weeks", "3 weeks", "4 weeks", "1 month", "3 months"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Quote")) {
                    Text(quote.text)
                        .foregroundColor(.secondary)
                        .disabled(true)
                    if let author = quote.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .disabled(true)
                    }
                }
                Section(header: Text("Reminder Frequency")) {
                    Picker("Frequency", selection: $selectedOption) {
                        ForEach(reminderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Set Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingReminderSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Delete existing reminder for this quote, if any
//                        let fetchRequest = FetchDescriptor<QuoteReminder>(predicate: #Predicate<QuoteReminder> { $0.quoteID == quote.id })
//                        do {
//                            if let existingReminder = try modelContext.fetch(fetchRequest).first {
//                                modelContext.delete(existingReminder)
//                            }
//                        } catch {
//                            print("Error deleting existing reminder: \(error)")
//                        }
//                        
//                        // Save new reminder
//                        let newReminder = QuoteReminder(quoteID: quote.id, reminderOption: selectedOption)
//                        modelContext.insert(newReminder)
//                        try? modelContext.save()
//                        showingReminderSheet = false
                    }
                }
            }
        }
    }
}

#Preview {
    QuoteReminderView(quote: Quote(text: "Sample quote", isCustom: true), showingReminderSheet: .constant(true))
        .modelContainer(for: [Quote.self, QuoteReminder.self], inMemory: true)
}
