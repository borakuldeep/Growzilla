//
//  GradientBackground.swift
//  grow-daily
//
//  Created by Kuldeep Bora on 9/13/25.
//


import SwiftUI

// Custom View Modifier for Gradient Background
struct GradientBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            // Conditional gradient based on color scheme
            if colorScheme == .light {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#FED7AA").opacity(0.4), // Peach orange (light mode)
                        Color(hex: "#F59E0B").opacity(0.5)  // Amber orange (light mode)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#D3D3D3").opacity(0.7), // Light grey
                        Color(hex: "#4B4B4B").opacity(0.8)  // Dark grey
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            content // Overlay the content on top of the gradient
        }
    }
}

// Extension to easily apply the modifier
extension View {
    func gradientBackground() -> some View {
        self.modifier(GradientBackground())
    }
}
