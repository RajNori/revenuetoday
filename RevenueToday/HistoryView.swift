//
//  HistoryView.swift
//  RevenueToday
//

import SwiftUI
import Charts
import CoreData
import UIKit

private struct DailyPL: Identifiable {
    let date: Date
    let income: Double
    let expenses: Double

    var id: TimeInterval { date.timeIntervalSince1970 }

    var net: Double { income - expenses }
}

private struct MonthGroup: Identifiable {
    let id: String
    let monthStart: Date
    let label: String
    let revenue: Double
    let expenses: Double
    let entries: [RevenueEntry]

    var net: Double { revenue - expenses }

    var margin: Int {
        guard revenue > 0 else { return 0 }
        return Int((net / revenue) * 100)
    }
}

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var fetchLimit = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()

    @State private var expandedMonthIDs: Set<String> = []

    private var allEntries: [RevenueEntry] {
        let request = RevenueEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", fetchLimit as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \RevenueEntry.date, ascending: false)
        ]
        return (try? viewContext.fetch(request)) ?? []
    }

    private var monthStarts: [Date] {
        let cal = Calendar.current
        var keys = Set<String>()
        var months: [Date] = []
        for entry in allEntries {
            let c = cal.dateComponents([.year, .month], from: entry.date ?? Date())
            let key = "\(c.year ?? 0)-\(c.month ?? 0)"
            guard keys.insert(key).inserted else { continue }
            var dc = DateComponents()
            dc.year = c.year
            dc.month = c.month
            dc.day = 1
            if let ms = cal.date(from: dc) {
                months.append(ms)
            }
        }
        return months.sorted { $0 > $1 }
    }

    private var monthGroups: [MonthGroup] {
        monthStarts.map { ms in
            let entries = monthEntries(for: ms)
            let revenue = entries.filter(\.isIncome).reduce(0) { $0 + $1.amount }
            let expenses = entries.filter(\.isExpense).reduce(0) { $0 + $1.amount }
            return MonthGroup(
                id: monthId(for: ms),
                monthStart: ms,
                label: monthTitleFormatter.string(from: ms),
                revenue: revenue,
                expenses: expenses,
                entries: entries
            )
        }
    }

    private var monthTitleFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }

    private var dailyData: [DailyPL] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        var grouped: [Date: (Double, Double)] = [:]

        for entry in allEntries {
            guard let date = entry.date, date >= thirtyDaysAgo else { continue }
            let day = calendar.startOfDay(for: date)
            if entry.isExpense {
                grouped[day, default: (0, 0)].1 += entry.amount
            } else {
                grouped[day, default: (0, 0)].0 += entry.amount
            }
        }

        return grouped.map { date, values in
            DailyPL(date: date, income: values.0, expenses: values.1)
        }
        .sorted { $0.date < $1.date }
    }

    private var heroFontSize: CGFloat {
        UIScreen.isSmall ? 40 : 48
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection

                        chartCard
                            .padding(.horizontal, Theme.Layout.gutter)
                            .padding(.bottom, Theme.Layout.sectionSpacing)

                        Text("HISTORY")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textTertiary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Layout.gutter)
                            .padding(.bottom, 8)

                        ForEach(monthGroups) { month in
                            monthCard(month)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchLimit = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THIS MONTH")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
            Text(formatCurrency(viewContext.thisMonthTotal()))
                .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Layout.gutter)
        .padding(.top, 16)
        .padding(.bottom, Theme.Layout.sectionSpacing)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST 30 DAYS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)

            Chart {
                ForEach(dailyData) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Income", day.income),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color(hex: "00C896").opacity(0.8))
                    .offset(x: -4)

                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Expenses", day.expenses),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color(hex: "FF6B6B").opacity(0.8))
                    .offset(x: 4)
                }

                ForEach(dailyData) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Net", day.net)
                    )
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    .symbol(.circle)
                    .symbolSize(20)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            HStack(spacing: 16) {
                legendItem(color: Color(hex: "00C896"), label: "Income")
                legendItem(color: Color(hex: "FF6B6B"), label: "Expenses")
                legendItem(color: .white.opacity(0.6), label: "Net", isDashed: true)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(Theme.Layout.cardPaddingH)
        .revenueCardBackground()
    }

    private func legendItem(color: Color, label: String, isDashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if isDashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 1.5)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 12, height: 8)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "48484C"))
        }
    }

    private func marginColor(_ margin: Int) -> Color {
        switch margin {
        case 80...:
            return Color(hex: "00C896")
        case 60..<80:
            return .white
        case 40..<60:
            return Color(hex: "FF9500")
        default:
            return Color(hex: "FF6B6B")
        }
    }

    @ViewBuilder
    private func monthCard(_ month: MonthGroup) -> some View {
        let expanded = expandedMonthIDs.contains(month.id)

        VStack(spacing: 0) {
            HStack {
                Text(month.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(formatCurrency(month.net))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(month.net >= 0 ? Theme.accent : Theme.danger)
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.Layout.cardPaddingH)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleMonth(month.id)
            }

            if expanded {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, Theme.Layout.cardPaddingH)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Revenue")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(formatCurrency(month.revenue))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "00C896"))
                    }
                    if month.expenses > 0 {
                        HStack {
                            Text("Expenses")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("- \(formatCurrency(month.expenses))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "FF6B6B"))
                        }
                    }
                    HStack {
                        Text("Net")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(formatCurrency(month.net))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    HStack {
                        Text("Margin")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(month.margin)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(marginColor(month.margin))
                    }
                }
                .padding(.horizontal, Theme.Layout.cardPaddingH)
                .padding(.vertical, 12)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, Theme.Layout.cardPaddingH)

                ForEach(month.entries, id: \.objectID) { entry in
                    HStack(alignment: .center, spacing: 10) {
                        Circle()
                            .fill(entry.isExpense ? Color(hex: "FF6B6B") : Theme.accent)
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.isExpense ? "- " : "")\(formatCurrency(entry.amount))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(entry.isExpense ? Color(hex: "FF6B6B") : Theme.textPrimary)
                            if let label = entry.label, !label.isEmpty {
                                Text(label)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                        if let date = entry.date {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(date, style: .time)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "48484C"))
                                Text(date, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "48484C").opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Layout.cardPaddingH)
                    .padding(.vertical, 10)
                }
            }
        }
        .revenueCardBackground()
        .padding(.horizontal, Theme.Layout.gutter)
        .padding(.bottom, Theme.Layout.cardSpacing)
    }

    private func toggleMonth(_ id: String) {
        if expandedMonthIDs.contains(id) {
            expandedMonthIDs.remove(id)
        } else {
            expandedMonthIDs.insert(id)
        }
    }

    private func monthId(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)"
    }

    private func monthEntries(for monthStart: Date) -> [RevenueEntry] {
        let month = (try? viewContext.entriesForMonth(date: monthStart)) ?? []
        return month.filter { ($0.date ?? .distantPast) >= fetchLimit }
    }
}
