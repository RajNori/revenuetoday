//
//  AddEntryView.swift
//  RevenueToday
//

import SwiftUI
import CoreData
import UIKit

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    private let entry: RevenueEntry?

    @State private var amountString: String
    @State private var label: String
    @State private var entryType: String
    @State private var showValidationAlert = false

    init(entry: RevenueEntry? = nil) {
        self.entry = entry
        _amountString = State(initialValue: Self.initialAmountString(for: entry))
        _label = State(initialValue: entry?.label ?? "")
        _entryType = State(initialValue: entry?.entryType ?? "income")
    }

    private var isEditing: Bool {
        entry != nil
    }

    private var sheetTitle: String {
        if isEditing {
            return entryType == "expense" ? "Edit Expense" : "Edit Payment"
        }
        return entryType == "expense" ? "Log Expense" : "Log Payment"
    }

    private var primaryButtonTitle: String {
        if isEditing {
            return "Save changes"
        }
        return entryType == "expense" ? "Log expense" : "Log payment"
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

    private var amountDisplayColor: Color {
        if amountString.isEmpty {
            return Color(hex: "48484C")
        }
        return entryType == "income" ? Color(hex: "00C896") : Color(hex: "FF6B6B")
    }

    private var canSubmitAmount: Bool {
        !amountString.isEmpty
    }

    private var primaryButtonFill: Color {
        guard canSubmitAmount else { return Theme.elevatedFill }
        return entryType == "expense" ? Color(hex: "FF6B6B") : Theme.accent
    }

    private var primaryButtonForeground: Color {
        canSubmitAmount ? Color.black : Theme.textTertiary
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
                Text(sheetTitle)
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

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        entryType = "income"
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                        Text("Income")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(entryType == "income" ? .black : Color(hex: "8A8A8E"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entryType == "income" ? Color(hex: "00C896") : Color(hex: "1C1C22"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        entryType == "income" ? Color.clear : Color.white.opacity(0.06),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        entryType = "expense"
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                        Text("Expense")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(entryType == "expense" ? .white : Color(hex: "8A8A8E"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entryType == "expense" ? Color(hex: "FF6B6B") : Color(hex: "1C1C22"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        entryType == "expense" ? Color.clear : Color.white.opacity(0.06),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            VStack(spacing: 4) {
                Group {
                    if amountString.isEmpty {
                        Text("$0")
                            .foregroundStyle(amountDisplayColor)
                    } else {
                        Text(displayAmount)
                            .foregroundStyle(amountDisplayColor)
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
                    .foregroundStyle(primaryButtonForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(primaryButtonFill)
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
            existing.entryType = entryType
        } else {
            let newEntry = RevenueEntry(context: viewContext)
            newEntry.id = UUID()
            newEntry.amount = amount
            newEntry.label = labelOrNil
            newEntry.entryType = entryType
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
