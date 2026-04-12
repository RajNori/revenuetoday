//
//  Theme.swift
//  RevenueToday
//

import SwiftUI
import UIKit

enum Theme {
    /// Layer 0 — page background
    static let background = Color(hex: 0x0A0A0F)
    static let pageBackground = Color(hex: 0x0A0A0F)

    /// Layer 1 — card surfaces
    static let card = Color(hex: 0x141418)
    static let cardFill = Color(hex: 0x141418)

    /// Layer 2 — elevated / interactive keys
    static let elevatedFill = Color(hex: 0x1C1C22)

    /// Layer 3 — inputs
    static let inputFill = Color(hex: 0x242429)

    static let accent = Color(hex: 0x00C896)
    static let danger = Color(hex: 0xFF6B6B)

    static let textPrimary = Color(hex: 0xFFFFFF)
    static let textMuted = Color(hex: 0x888888)
    static let textSecondary = Color(hex: 0x8A8A8E)
    static let textTertiary = Color(hex: 0x48484C)

    static let cardCornerRadius: CGFloat = 16

    enum Layout {
        static let gutter: CGFloat = 20
        static let cardPaddingH: CGFloat = 16
        static let cardPaddingV: CGFloat = 14
        static let sectionSpacing: CGFloat = 24
        static let cardSpacing: CGFloat = 8
        static let cornerCard: CGFloat = 16
        static let cornerInput: CGFloat = 12
    }
}

extension UIScreen {
    static var isSmall: Bool {
        main.bounds.height < 700
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") {
            s.removeFirst()
        }
        guard s.count == 6, let value = UInt32(s, radix: 16) else {
            self = .clear
            return
        }
        self.init(hex: value)
    }
}

extension View {
    /// Notion-style bordered card (fill #141418 + hairline stroke).
    func revenueCardBackground(cornerRadius: CGFloat = Theme.Layout.cornerCard) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }
}

func formatCurrency(_ amount: Double) -> String {
    if amount.truncatingRemainder(dividingBy: 1) == 0 {
        return "$\(Int(amount).formatted())"
    }
    return amount.formatted(.currency(code: "USD"))
}
