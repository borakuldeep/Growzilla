//  SettingsView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI

struct SettingsView: View {
    @Binding var notificationTimes: [[String: Int]]
    @Binding var showingSettings: Bool
    @State private var showTimePicker = false
    @State private var newTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0))!
    @State private var isPickerInteracted = false
    
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
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                notificationTimes.append(["hour": components.hour!, "minute": components.minute!])
                                showTimePicker = false
                                isPickerInteracted = false
                                newTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0))!
                                saveAndReschedule()
                            }
                            .disabled(!isPickerInteracted)
                        }
                    } else {
                        Button("Schedule new time") {
                            showTimePicker = true
                            isPickerInteracted = false
                            newTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0))!
                        }
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
    SettingsView(notificationTimes: .constant([]), showingSettings: .constant(false))
}
