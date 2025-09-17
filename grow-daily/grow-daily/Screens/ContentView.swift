//
//  ContentView.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//


//  ContentView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedQuote: Quote?
    @State private var showingDetail = false
    @State private var showingSettings = false
    @State private var notificationTimes: [[String: Int]] = []
    
    var body: some View {
        TabView {
            HomeView(selectedQuote: $selectedQuote,showingSettings: $showingSettings, notificationTimes: $notificationTimes)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            FavoritesView(showingDetail: $showingDetail)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
            
            CustomQuotesView(showingDetail: $showingDetail)
                .tabItem {
                    Label("Custom", systemImage: "pencil")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Quote.self, inMemory: true)
}
