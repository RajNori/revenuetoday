//
//  HistoryView.swift
//  RevenueToday
//

import SwiftUI
import Charts
import CoreData
import UIKit

private struct MonthGroup: Identifiable {
    let id: String
    let monthStart: Date
    let label: String
    let total: Double
    let entries: [RevenueEntry]
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
            let total = entries.reduce(0) { $0 + $1.amount }
            return MonthGroup(
                id: monthId(for: ms),
                monthStart: ms,
                label: monthTitleFormatter.string(from: ms),
                total: total,
                entries: entries
            )
        }
    }

    private var monthTitleFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }

    private var dailyPoints: [(date: Date, total: Double)] {
        viewContext.dailyTotals(days: 30).map { (date: $0.0, total: $0.1) }
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
                ForEach(dailyPoints, id: \.date.timeIntervalSince1970) { point in
                    BarMark(
                        x: .value("Day", point.date),
                        y: .value("Amount", point.total)
                    )
                    .foregroundStyle(
                        Calendar.current.isDate(point.date, inSameDayAs: Date())
                        ? Theme.accent
                        : Theme.accent.opacity(0.45)
                    )
                }
            }
            .frame(height: 160)
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
        }
        .padding(Theme.Layout.cardPaddingH)
        .revenueCardBackground()
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
                Text(formatCurrency(month.total))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
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

                ForEach(month.entries, id: \.objectID) { entry in
                    HStack(alignment: .center, spacing: 10) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatCurrency(entry.amount))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
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
