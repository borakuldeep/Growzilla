//
//  QuoteDetailView.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/7/25.
//


//  QuoteDetailView.swift
//  Quotes
//
//  Created by Grok on 9/7/2025.
//  Copyright © 2025 xAI. All rights reserved.

import SwiftUI
import SwiftData

struct QuoteDetailView: View {
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

#Preview {
    QuoteDetailView(quote: Quote(text: "Sample quote", isCustom: true))
}
