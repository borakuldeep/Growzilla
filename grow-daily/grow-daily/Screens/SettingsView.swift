// SettingsView.swift
// Quotes
//
// Created by Grok on 9/7/2025.
// Copyright © 2025 xAI. All rights reserved.

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var notificationTimes: [[String: Int]]
    @Binding var showingSettings: Bool
    @State private var showTimePicker = false
    @State private var newTime = Calendar.current.date(
        from: DateComponents(hour: 0, minute: 0)
    )!
    @State private var isPickerInteracted = false
    @State private var initialNotificationTimes: [[String: Int]]  // Store initial state
    @State private var tempNotificationTimes: [[String: Int]]  // Temporary state for changes

    // Computed property to check if tempNotificationTimes has changed
    private var hasChanges: Bool {
        tempNotificationTimes != initialNotificationTimes
    }

    init(
        notificationTimes: Binding<[[String: Int]]>,
        showingSettings: Binding<Bool>
    ) {
        self._notificationTimes = notificationTimes
        self._showingSettings = showingSettings
        self._initialNotificationTimes = State(
            initialValue: notificationTimes.wrappedValue
        )
        self._tempNotificationTimes = State(
            initialValue: notificationTimes.wrappedValue
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Notification Times") {
                    if tempNotificationTimes.isEmpty {
                        Text("No notification times set")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(tempNotificationTimes.indices, id: \.self) {
                            index in
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: {
                                        let time = tempNotificationTimes[index]
                                        return Calendar.current.date(
                                            from: DateComponents(
                                                hour: time["hour"],
                                                minute: time["minute"]
                                            )
                                        )!
                                    },
                                    set: { newValue in
                                        let components = Calendar.current
                                            .dateComponents(
                                                [.hour, .minute],
                                                from: newValue
                                            )
                                        tempNotificationTimes[index] = [
                                            "hour": components.hour!,
                                            "minute": components.minute!,
                                        ]
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        .onDelete { indices in
                            tempNotificationTimes.remove(atOffsets: indices)
                        }
                    }
                }
                Section {
                    if showTimePicker {
                        HStack {
                            if !isPickerInteracted {
                                Text("Tap or pick a time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            DatePicker(
                                "",
                                selection: $newTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .onChange(of: newTime) {
                                isPickerInteracted = true
                            }
                            Button("Add") {
                                let components = Calendar.current
                                    .dateComponents(
                                        [.hour, .minute],
                                        from: newTime
                                    )
                                tempNotificationTimes.append([
                                    "hour": components.hour!,
                                    "minute": components.minute!,
                                ])
                                showTimePicker = false
                                isPickerInteracted = false
                                newTime = Calendar.current.date(
                                    from: DateComponents(hour: 0, minute: 0)
                                )!
                            }
                            .disabled(!isPickerInteracted)
                        }
                    } else {
                        Button("Schedule new time") {
                            showTimePicker = true
                            isPickerInteracted = false
                            newTime = Calendar.current.date(
                                from: DateComponents(hour: 0, minute: 0)
                            )!
                        }.disabled(notificationTimes.count >= 2)
                    }
                    Text("Only up to 2 daily notifications are allowed.").font(
                        .subheadline
                    ).opacity(0.7)
                }
                Section {
                    Text(
                        "A random quote will be delivered to you on these times daily."
                    ).font(.subheadline).opacity(0.7)
                }
            }
            .navigationTitle("Notification Settings")
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSettings = false
                    }.foregroundStyle(colorScheme == .dark ? .white : .blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        notificationTimes = tempNotificationTimes  // Update original binding
                        saveAndReschedule()
                        showingSettings = false
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(!hasChanges)  // Enable only if changes are detected
                }
            }
        }
    }

    private func saveAndReschedule() {
        print("notificationTimes in saveAndReschedule: \(notificationTimes)")
        //remove all pending notifications because already scheduled ones can't be edited
        removeAllNonFixedQuoteNotifications()
        UserDefaults.standard.set(
            notificationTimes,
            forKey: "notificationTimes"
        )
        scheduleNotifications()
    }
}

#Preview {
    SettingsView(
        notificationTimes: .constant([]),
        showingSettings: .constant(false)
    )
}
