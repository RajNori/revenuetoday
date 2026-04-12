//
//  AddEntryView.swift
//  RevenueToday
//

import SwiftUI
import CoreData
import UIKit

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    private let entry: RevenueEntry?

    @State private var amountString: String
    @State private var label: String
    @State private var showValidationAlert = false

    init(entry: RevenueEntry? = nil) {
        self.entry = entry
        _amountString = State(initialValue: Self.initialAmountString(for: entry))
        _label = State(initialValue: entry?.label ?? "")
    }

    private var isEditing: Bool {
        entry != nil
    }

    private var title: String {
        isEditing ? "Edit Payment" : "Log Payment"
    }

    private var primaryButtonTitle: String {
        isEditing ? "Save changes" : "Log payment"
    }

    private var heroDisplaySize: CGFloat {
        UIScreen.isSmall ? 48 : 56
    }

    private var calcKeyHeight: CGFloat {
        UIScreen.isSmall ? 52 : 60
    }

    /// Formats `amountString` for the large display (e.g. "$1,250" / "$99.50").
    private var displayAmount: String {
        guard !amountString.isEmpty else { return "" }
        if amountString == "." {
            return "$."
        }
        if amountString.hasSuffix("."), amountString.count > 1 {
            let base = String(amountString.dropLast())
            if let d = Double(base) {
                return formatCurrency(d) + "."
            }
        }
        if let d = Double(amountString) {
            return formatCurrency(d)
        }
        return "$" + amountString
    }

    private var canSubmitAmount: Bool {
        !amountString.isEmpty
    }

    private let keypadKeys = ["7", "8", "9", "4", "5", "6", "1", "2", "3", ".", "0", "⌫"]

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.Layout.gutter)
            .padding(.bottom, 24)

            VStack(spacing: 4) {
                Group {
                    if amountString.isEmpty {
                        Text("$0")
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        Text(displayAmount)
                            .foregroundStyle(Theme.accent)
                    }
                }
                .font(.system(size: heroDisplaySize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)

                Text("tap numbers below to enter amount")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .opacity(amountString.isEmpty ? 1 : 0)
            }
            .padding(.bottom, 20)

            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textTertiary)
                TextField(
                    "Client or project (optional)",
                    text: $label
                )
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .onChange(of: label) { newValue in
                    if newValue.count > 50 {
                        label = String(newValue.prefix(50))
                    }
                    if newValue.first == " " {
                        label = newValue.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.cardPaddingH)
            .padding(.vertical, Theme.Layout.cardPaddingV)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                    .fill(Theme.elevatedFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, Theme.Layout.gutter)
            .padding(.bottom, 20)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Layout.cardSpacing),
                    GridItem(.flexible(), spacing: Theme.Layout.cardSpacing),
                    GridItem(.flexible(), spacing: Theme.Layout.cardSpacing)
                ],
                spacing: Theme.Layout.cardSpacing
            ) {
                ForEach(keypadKeys, id: \.self) { key in
                    calcButton(key)
                }
            }
            .padding(.horizontal, Theme.Layout.gutter)
            .padding(.bottom, 16)

            Button {
                save()
            } label: {
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(canSubmitAmount ? Color.black : Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(canSubmitAmount ? Theme.accent : Theme.elevatedFill)
                    )
            }
            .disabled(!canSubmitAmount)
            .padding(.horizontal, Theme.Layout.gutter)
            .padding(.bottom, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pageBackground.ignoresSafeArea())
        .alert("Invalid Amount", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a valid amount between $0.01 and $999,999.99")
        }
    }

    @ViewBuilder
    private func calcButton(_ key: String) -> some View {
        if key == "⌫" {
            Button {
                handleKey(key)
            } label: {
                Text(key)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: calcKeyHeight)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                            .fill(Theme.elevatedFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .onLongPressGesture(minimumDuration: 0.5) {
                guard !amountString.isEmpty else { return }
                amountString = ""
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else {
            Button {
                handleKey(key)
            } label: {
                Text(key)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: calcKeyHeight)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                            .fill(Theme.elevatedFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerInput)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            backspace()
            return
        }
        appendKey(key)
    }

    private func appendKey(_ key: String) {
        if key == "." {
            guard !amountString.contains(".") else { return }
            guard amountString.count < 8 else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if amountString.isEmpty {
                amountString = "0."
            } else {
                amountString += "."
            }
            return
        }

        guard key.count == 1, key.first?.isNumber == true else { return }
        guard amountString.count < 8 else { return }

        if let dotIndex = amountString.firstIndex(of: ".") {
            let frac = amountString[amountString.index(after: dotIndex)...]
            if frac.count >= 2 {
                return
            }
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        amountString += key
    }

    private func backspace() {
        guard !amountString.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        amountString.removeLast()
    }

    private func save() {
        guard let amount = Double(amountString),
              amount >= 0.01,
              amount <= 999_999.99,
              !amountString.hasPrefix("-"),
              !amountString.hasSuffix(".")
        else {
            showValidationAlert = true
            return
        }

        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let labelOrNil = trimmedLabel.isEmpty ? nil : trimmedLabel

        if let existing = entry {
            existing.amount = amount
            existing.label = labelOrNil
        } else {
            let newEntry = RevenueEntry(context: viewContext)
            newEntry.id = UUID()
            newEntry.amount = amount
            newEntry.label = labelOrNil
            let now = Date()
            newEntry.date = now
            newEntry.createdAt = now
        }

        do {
            try viewContext.save()
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            dismiss()
        } catch {
            assertionFailure("Save failed: \(error)")
        }
    }

    private static func initialAmountString(for entry: RevenueEntry?) -> String {
        guard let entry else { return "" }
        let a = entry.amount
        if a.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(a))
        }
        return String(format: "%.2f", a)
    }
}
