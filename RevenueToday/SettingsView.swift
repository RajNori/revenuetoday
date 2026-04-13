//
//  SettingsView.swift
//  RevenueToday
//

import SwiftUI
import CoreData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("weeklyNotificationEnabled") private var weeklyNotificationEnabled = false
    @AppStorage("weeklyNotificationHour") private var weeklyNotificationHour = 9
    @AppStorage("drySpellEnabled") private var drySpellEnabled = false
    @AppStorage("drySpellDays") private var drySpellDays = 3
    @AppStorage("weeklyHours") private var weeklyHours: Double = 40
    @AppStorage("lastEntryTimestamp") private var lastEntryTimestamp: Double = 0

    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    notificationsSection
                    drySpellSection
                    hourlyRateSection
                    aboutSection
                }
                .padding(.bottom, 32)
            }
        }
        .onChange(of: lastEntryTimestamp) { _ in
            scheduleDrySpellNotification()
        }
        .onAppear {
            scheduleDrySpellNotification()
        }
        .alert("Notifications Blocked", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications for Revenue Today in Settings to receive weekly summaries.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "00C896"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func scheduleWeeklyNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    weeklyNotificationEnabled = true
                    createWeeklyNotification()
                } else {
                    weeklyNotificationEnabled = false
                    showPermissionAlert = true
                }
            }
        }
    }

    private func createWeeklyNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])

        let content = UNMutableNotificationContent()
        content.title = "Your week in revenue 💰"
        content.body = "Open Revenue Today to see last week's summary."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = weeklyNotificationHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func scheduleDrySpellNotification() {
        guard drySpellEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dry-spell"])

        let content = UNMutableNotificationContent()
        content.title = "Revenue check-in 📊"
        content.body = "\(drySpellDays) days without a payment logged. Everything ok?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(drySpellDays) * 86400,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "dry-spell",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Weekly Summary")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Every Monday morning")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8E"))
                    }
                    Spacer()
                    Toggle("", isOn: $weeklyNotificationEnabled)
                        .tint(Color(hex: "00C896"))
                        .onChange(of: weeklyNotificationEnabled) { enabled in
                            if enabled {
                                scheduleWeeklyNotification()
                            } else {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])
                            }
                        }
                }
                .padding(16)

                if weeklyNotificationEnabled {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    HStack {
                        Text("Send at")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        Spacer()
                        Picker("Hour", selection: $weeklyNotificationHour) {
                            ForEach([7, 8, 9, 10, 11, 12], id: \.self) { hour in
                                Text("\(hour):00 am").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color(hex: "00C896"))
                        .onChange(of: weeklyNotificationHour) { _ in
                            if weeklyNotificationEnabled {
                                createWeeklyNotification()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private var drySpellSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DRY SPELL ALERT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No Payment Alert")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Notify if no revenue logged")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8E"))
                    }
                    Spacer()
                    Toggle("", isOn: $drySpellEnabled)
                        .tint(Color(hex: "00C896"))
                        .onChange(of: drySpellEnabled) { enabled in
                            if enabled {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                                    DispatchQueue.main.async {
                                        if granted {
                                            scheduleDrySpellNotification()
                                        } else {
                                            drySpellEnabled = false
                                            showPermissionAlert = true
                                        }
                                    }
                                }
                            } else {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dry-spell"])
                            }
                        }
                }
                .padding(16)

                if drySpellEnabled {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    HStack {
                        Text("After")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        Spacer()
                        Picker("Days", selection: $drySpellDays) {
                            ForEach([2, 3, 5, 7, 14], id: \.self) { day in
                                Text("\(day) days").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color(hex: "00C896"))
                        .onChange(of: drySpellDays) { _ in
                            if drySpellEnabled {
                                scheduleDrySpellNotification()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private var effectiveHourlyRate: Double? {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return nil
        }

        let daysElapsed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 1
        let weeksElapsed = Double(daysElapsed) / 7.0
        let hoursWorked = weeklyHours * weeksElapsed

        guard hoursWorked > 0 else { return nil }

        let request = RevenueEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startOfMonth as CVarArg,
            now as CVarArg
        )
        let entries = (try? viewContext.fetch(request)) ?? []
        let monthTotal = entries.filter(\.isIncome).reduce(0) { $0 + $1.amount }

        guard monthTotal > 0 else { return nil }
        return monthTotal / hoursWorked
    }

    private var hourlyRateSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HOURLY RATE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Hours per week")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Your typical working hours")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8E"))
                    }
                    Spacer()
                    Picker("Hours", selection: $weeklyHours) {
                        ForEach([10, 20, 30, 40, 50, 60], id: \.self) { h in
                            Text("\(h)h").tag(Double(h))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "00C896"))
                }
                .padding(16)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Effective rate this month")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        Text("Based on logged revenue")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "48484C"))
                    }
                    Spacer()
                    if let rate = effectiveHourlyRate {
                        Text("\(formatCurrency(rate))/hr")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "00C896"))
                    } else {
                        Text("—")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "48484C"))
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ABOUT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8A8A8E"))
                }
                .padding(16)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                if let privacyURL = URL(string: "https://rajnori.github.io/revenuetoday/privacy/") {
                    Link(destination: privacyURL) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "48484C"))
                        }
                        .padding(16)
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                if let supportURL = URL(string: "https://rajnori.github.io/revenuetoday/support/") {
                    Link(destination: supportURL) {
                        HStack {
                            Text("Support")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "48484C"))
                        }
                        .padding(16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(amount).formatted())"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
