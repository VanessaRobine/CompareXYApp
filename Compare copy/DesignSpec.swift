//
//  DesignSpec.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/18/26.
//

import Foundation
import SwiftUI

// MARK: - Background

extension LinearGradient {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.60, blue: 0.65),
            Color(red: 0.02, green: 0.40, blue: 0.45)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Colors

extension Color {
    static let card = Color.white.opacity(0.10)
    static let cardBorder = Color.white.opacity(0.15)
    static let pill = Color.white.opacity(0.18)
}
extension Color {

    // Background stays your teal
    static let brandTealTop = Color(red: 0.10, green: 0.65, blue: 0.67)
    static let brandTealBottom = Color(red: 0.05, green: 0.35, blue: 0.38)

    // 🔥 New accents (NO purple)
    static let accentPrimary = Color(red: 0.20, green: 0.55, blue: 0.95)
    static let accentSecondary = Color(red: 0.10, green: 0.75, blue: 0.80)

    static let cardBackground = Color.white.opacity(0.08)


    // 🟢 Success / highlight
    static let accentSuccess = Color(red: 0.20, green: 0.80, blue: 0.55)
}

// MARK: - Card Style

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.cardBorder)
            )
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}

// MARK: - Pill Style

struct PillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.pill)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2))
            )
            .cornerRadius(20)
    }
}

extension View {
    func pillStyle() -> some View {
        self.modifier(PillModifier())
    }
}
