//
//  TodayView.swift
//  RevenueToday
//

import SwiftUI
import CoreData
import UIKit

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(fetchRequest: RevenueEntry.todayFetchRequest(), animation: .default)
    private var entries: FetchedResults<RevenueEntry>

    @State private var showAddSheet = false
    @State private var entryToEdit: RevenueEntry?
    @State private var entryToDelete: RevenueEntry?
    @State private var showDeleteAlert = false

    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @State private var hintOffset: CGFloat = 0

    @AppStorage("dailyGoal") private var dailyGoal: Double = 500
    @AppStorage("lastGoalDate") private var lastGoalDate: String = ""
    @State private var showGoalBanner = false
    @State private var showGoalSetter = false
    @State private var goalInput = ""

    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("lastPaymentDate") private var lastPaymentDate: String = ""
    @AppStorage("longestStreak") private var longestStreak = 0

    @State private var showRepeatToast = false
    @State private var repeatToastLabel = ""

    @AppStorage("bestDayAmount") private var bestDayAmount: Double = 0
    @AppStorage("bestDayDate") private var bestDayDate: String = ""
    @State private var showBestDayBanner = false

    @State private var showEntryLimitAlert = false
    @State private var showSettings = false

    @AppStorage("lastEntryTimestamp") private var lastEntryTimestamp: Double = 0

    private let dailyEntryLimit = 100
    private let dailyEntryWarning = 50

    private var todayEntryCount: Int {
        entries.count
    }

    private var todayTotal: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    private var monthTotal: Double {
        viewContext.thisMonthTotal()
    }

    private var weekdayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }

    private var fullDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    private var paceIndicator: (text: String, isAhead: Bool)? {
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
              let endOfLastMonthSamePeriod = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: startOfLastMonth)
        else {
            return nil
        }

        let thisMonthRequest: NSFetchRequest<RevenueEntry> = RevenueEntry.fetchRequest()
        thisMonthRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startOfMonth as NSDate,
            now as NSDate
        )
        let thisMonthEntries = (try? viewContext.fetch(thisMonthRequest)) ?? []
        let thisMonthTotalPace = thisMonthEntries.reduce(0) { $0 + $1.amount }

        let lastMonthRequest: NSFetchRequest<RevenueEntry> = RevenueEntry.fetchRequest()
        lastMonthRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startOfLastMonth as NSDate,
            endOfLastMonthSamePeriod as NSDate
        )
        let lastMonthEntries = (try? viewContext.fetch(lastMonthRequest)) ?? []
        let lastMonthTotalPace = lastMonthEntries.reduce(0) { $0 + $1.amount }

        guard lastMonthTotalPace > 0 else { return nil }

        let diff = thisMonthTotalPace - lastMonthTotalPace
        let isAhead = diff >= 0
        let direction = isAhead ? "ahead of" : "behind"
        return (
            text: "\(formatCurrency(abs(diff))) \(direction) last month at this point",
            isAhead: isAhead
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.pageBackground
                    .ignoresSafeArea()

                List {
                    Section {
                        headerSection
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        statsCard
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: Theme.Layout.gutter, bottom: 0, trailing: Theme.Layout.gutter))
                            .listRowSeparator(.hidden)
                    }

                    if let pace = paceIndicator {
                        Section {
                            paceRow(pace: pace)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSeparator(.hidden)
                        }
                    }

                    Section {
                        Text("PAYMENTS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, Theme.Layout.sectionSpacing)
                            .padding(.bottom, 4)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: Theme.Layout.gutter, bottom: 0, trailing: Theme.Layout.gutter))
                            .listRowSeparator(.hidden)

                        if entries.isEmpty {
                            emptyPaymentsCard
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: Theme.Layout.gutter, bottom: 0, trailing: Theme.Layout.gutter))
                                .listRowSeparator(.hidden)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(entries.enumerated()), id: \.1.objectID) { index, entry in
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let dayTitle = daySeparatorTitleIfNeeded(at: index, for: entry) {
                                            Text(dayTitle)
                                                .font(.system(size: 11, weight: .semibold))
                                                .tracking(1.2)
                                                .foregroundColor(Color(hex: "48484C"))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, 20)
                                                .padding(.top, 8)
                                        }
                                        entryRow(entry, isFirst: index == 0)
                                            .padding(.horizontal, 20)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    showDeleteConfirmation(for: entry)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                Button {
                                                    entryToEdit = entry
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(Theme.elevatedFill)
                                            }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(
                                EdgeInsets(
                                    top: Theme.Layout.cardSpacing / 2,
                                    leading: 0,
                                    bottom: Theme.Layout.cardSpacing / 2,
                                    trailing: 0
                                )
                            )
                        }

                        if !entries.isEmpty,
                           todayEntryCount >= dailyEntryWarning,
                           todayEntryCount < dailyEntryLimit {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "FF6B6B"))
                                Text("\(dailyEntryLimit - todayEntryCount) entries remaining today")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "8A8A8E"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.pageBackground)

                if showBestDayBanner {
                    VStack {
                        HStack(spacing: 10) {
                            Text("🏆")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Best Day Ever!")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(formatCurrency(bestDayAmount))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "00C896"))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1C1C22"))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color(hex: "00C896").opacity(0.4),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showBestDayBanner)
                    .zIndex(997)
                }

                if showRepeatToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "00C896"))
                                .font(.system(size: 15))
                            Text("Logged again: \(repeatToastLabel)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1C1C22"))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color.white.opacity(0.1),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showRepeatToast)
                    .zIndex(998)
                }

                if showGoalBanner {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "00C896"))
                                .font(.system(size: 18))
                            Text("Daily goal reached! 🎉")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1C1C22"))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color(hex: "00C896").opacity(0.4),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showGoalBanner)
                    .zIndex(999)
                }

                Button {
                    guard todayEntryCount < dailyEntryLimit else {
                        showEntryLimitAlert = true
                        return
                    }
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Theme.accent)
                                .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 4)
                        )
                }
                .padding(.trailing, Theme.Layout.gutter)
                .padding(.bottom, 24)
                .accessibilityLabel("Log new revenue")
                .accessibilityAddTraits(.isButton)
                .zIndex(1000)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: todayTotal) { _, newValue in
                let formatter = ISO8601DateFormatter()
                let today = formatter.string(from: Calendar.current.startOfDay(for: Date()))
                if newValue >= dailyGoal, lastGoalDate != today {
                    lastGoalDate = today
                    showGoalBanner = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showGoalBanner = false
                        }
                    }
                }
                checkBestDay()
            }
            .onChange(of: entries.count) { _, _ in
                if !entries.isEmpty {
                    updateStreak()
                }
                lastEntryTimestamp = Date().timeIntervalSince1970
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEntryView()
        }
        .sheet(item: $entryToEdit) { entry in
            AddEntryView(entry: entry)
        }
        .sheet(isPresented: $showGoalSetter) {
            goalSetterSheet
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Delete entry?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let e = entryToDelete {
                    withAnimation {
                        viewContext.delete(e)
                        try? viewContext.save()
                    }
                }
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("This payment entry will be removed.")
        }
        .alert("Daily limit reached", isPresented: $showEntryLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've logged \(dailyEntryLimit) payments today. That's the daily limit. If you need to log more, consider combining smaller payments into one entry.")
        }
    }

    private var goalSetterSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            Text("Daily Revenue Goal")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            HStack {
                Text("$")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "00C896"))
                TextField("500", text: $goalInput)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1C1C22"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Button("Save Goal") {
                if let val = Double(goalInput), val > 0 {
                    dailyGoal = val
                }
                showGoalSetter = false
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(Color(hex: "00C896"))
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(hex: "0A0A0F").ignoresSafeArea())
        .onAppear {
            goalInput = String(Int(dailyGoal))
        }
    }

    private func paceRow(pace: (text: String, isAhead: Bool)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: pace.isAhead ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(pace.isAhead ? Color(hex: "00C896") : Theme.danger)

            Text(pace.text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(pace.isAhead ? Color(hex: "00C896").opacity(0.8) : Theme.danger.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(pace.isAhead ? Color(hex: "00C896").opacity(0.08) : Theme.danger.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            pace.isAhead ? Color(hex: "00C896").opacity(0.15) : Theme.danger.opacity(0.15),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.horizontal, Theme.Layout.gutter)
        .padding(.top, 12)
    }

    private func repeatEntry(_ entry: RevenueEntry) {
        let toastLabel = entry.label ?? formatCurrency(entry.amount)
        let newEntry = RevenueEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.amount = entry.amount
        newEntry.label = entry.label
        newEntry.date = Date()
        newEntry.createdAt = Date()
        do {
            try viewContext.save()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            repeatToastLabel = toastLabel
            showRepeatToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showRepeatToast = false
                }
            }
        } catch {
            viewContext.rollback()
            print("Repeat entry failed: \(error)")
        }
    }

    private func checkBestDay() {
        let previousBest = bestDayAmount
        guard todayTotal > previousBest else { return }
        let formatter = ISO8601DateFormatter()
        let todayStr = formatter.string(from: Calendar.current.startOfDay(for: Date()))
        bestDayAmount = todayTotal
        bestDayDate = todayStr
        showBestDayBanner = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showBestDayBanner = false
            }
        }
    }

    private func updateStreak() {
        let formatter = ISO8601DateFormatter()
        let todayStr = formatter.string(from: Calendar.current.startOfDay(for: Date()))
        guard let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: Date())
        ) else {
            return
        }
        let yesterdayStr = formatter.string(from: yesterday)

        if lastPaymentDate == todayStr { return }

        if lastPaymentDate == yesterdayStr {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastPaymentDate = todayStr
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(weekdayFormatter.string(from: Date()).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "48484C"))
                Text(fullDateFormatter.string(from: Date()))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "48484C"))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "141418"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S REVENUE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(Color(hex: "48484C"))
                    Text(formatCurrency(todayTotal))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "00C896"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .accessibilityLabel("Today's revenue: \(formatCurrency(todayTotal))")
                    Text("Goal: \(formatCurrency(dailyGoal))")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "48484C"))
                        .onTapGesture { showGoalSetter = true }
                }
                Spacer()
                GoalRingView(
                    progress: dailyGoal > 0 ? todayTotal / dailyGoal : 0,
                    todayTotal: todayTotal,
                    goal: dailyGoal
                )
            }
            .padding(16)

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack {
                Text("THIS MONTH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "48484C"))
                Spacer()
                Text(formatCurrency(monthTotal))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(16)

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack {
                HStack(spacing: 6) {
                    Text(currentStreak > 0 ? "🔥" : "💤")
                        .font(.system(size: 14))
                    Text(currentStreak == 1 ? "1 day streak" : "\(currentStreak) day streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Best: \(longestStreak) days")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "48484C"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack {
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.system(size: 13))
                    Text("Best day")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(bestDayAmount > 0 ? formatCurrency(bestDayAmount) : "—")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "00C896"))
                    if !bestDayDate.isEmpty,
                       let date = ISO8601DateFormatter().date(from: bestDayDate) {
                        Text(date, style: .date)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "48484C"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .revenueCardBackground()
    }

    private var emptyPaymentsCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 28))
                .foregroundStyle(Theme.textTertiary)
            Text("No payments logged today")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text("Tap + to log your first payment")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .revenueCardBackground()
    }

    private func showDeleteConfirmation(for entry: RevenueEntry) {
        entryToDelete = entry
        showDeleteAlert = true
    }

    private func dateHeader(for entry: RevenueEntry) -> String {
        guard let date = entry.date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        }
        if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    /// Header when the day changes vs the previous row (always for the first row).
    private func daySeparatorTitleIfNeeded(at index: Int, for entry: RevenueEntry) -> String? {
        let all = Array(entries)
        let calendar = Calendar.current
        if index > 0 {
            let prev = all[index - 1]
            if calendar.isDate(prev.date ?? Date(), inSameDayAs: entry.date ?? Date()) {
                return nil
            }
        }
        let title = dateHeader(for: entry)
        return title.isEmpty ? nil : title
    }

    @ViewBuilder
    private func entryRow(_ entry: RevenueEntry, isFirst: Bool = false) -> some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(formatCurrency(entry.amount))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if let label = entry.label, !label.isEmpty {
                        Text(label)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Text(timeFormatter.string(from: entry.date ?? Date()))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Theme.textTertiary)
            }

            if isFirst, !hasSeenSwipeHint {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 10))
                    Text("Swipe")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "48484C"))
                .padding(.trailing, 12)
                .offset(x: hintOffset)
                .allowsHitTesting(false)
                .onAppear {
                    guard !hasSeenSwipeHint else { return }
                    withAnimation(
                        .easeInOut(duration: 0.4)
                            .delay(1.0)
                            .repeatCount(2, autoreverses: true)
                    ) {
                        hintOffset = -8
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hintOffset = 0
                        }
                        hasSeenSwipeHint = true
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Layout.cardPaddingH)
        .padding(.vertical, Theme.Layout.cardPaddingV)
        .revenueCardBackground()
        .contentShape(Rectangle())
        .onTapGesture {
            entryToEdit = entry
        }
        .contextMenu {
            Button {
                repeatEntry(entry)
            } label: {
                Label("Log Again", systemImage: "arrow.clockwise")
            }

            Button {
                entryToEdit = entry
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                entryToDelete = entry
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: entry))
    }

    private func accessibilityLabel(for entry: RevenueEntry) -> String {
        let amt = formatCurrency(entry.amount)
        if let label = entry.label, !label.isEmpty {
            return "\(amt) from \(label)"
        }
        return amt
    }
}

// MARK: - Goal ring

private struct GoalRingView: View {
    let progress: Double
    let todayTotal: Double
    let goal: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 6)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    progress >= 1.0
                        ? Color(hex: "00C896")
                        : Color(hex: "00C896").opacity(0.7),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

            VStack(spacing: 1) {
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("of goal")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "48484C"))
            }
        }
    }
}
