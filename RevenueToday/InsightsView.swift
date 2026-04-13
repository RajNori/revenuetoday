//
//  InsightsView.swift
//  RevenueToday
//

import SwiftUI
import CoreData

enum LeaderboardPeriod: String, CaseIterable {
    case thisMonth = "This Month"
    case allTime = "All Time"
}

struct ClientTotal: Identifiable {
    let id: String
    let name: String
    let total: Double
    let entryCount: Int
    let percentage: Double
}

struct InsightsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RevenueEntry.date, ascending: true)],
        animation: .default
    )
    private var allEntries: FetchedResults<RevenueEntry>

    @State private var selectedDay: Date?
    @State private var leaderboardPeriod: LeaderboardPeriod = .allTime

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    yearGridSection
                    leaderboardSection
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("INSIGHTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))
            Text("Your revenue patterns")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    private var yearData: [Date: Double] {
        let calendar = Calendar.current
        var result: [Date: Double] = [:]

        for entry in allEntries {
            guard let date = entry.date else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            result[startOfDay, default: 0] += entry.amount
        }
        return result
    }

    private var yearDays: [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return []
        }
        let dayCount = calendar.range(of: .day, in: .year, for: startOfYear)?.count ?? 365
        return (0..<dayCount).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfYear)
        }
    }

    private var maxDayRevenue: Double {
        yearData.values.max() ?? 1
    }

    private func cellColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let amount = yearData[startOfDay] ?? 0

        if startOfDay > calendar.startOfDay(for: Date()) {
            return Color.white.opacity(0.04)
        }

        if amount == 0 {
            return Color.white.opacity(0.06)
        }

        let ratio = amount / maxDayRevenue
        switch ratio {
        case 0..<0.25:
            return Color(hex: "00C896").opacity(0.25)
        case 0.25..<0.5:
            return Color(hex: "00C896").opacity(0.5)
        case 0.5..<0.75:
            return Color(hex: "00C896").opacity(0.75)
        default:
            return Color(hex: "00C896")
        }
    }

    private var monthLabelsRow: some View {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return HStack(spacing: 0) {
            ForEach(months, id: \.self) { month in
                Text(month)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(Color(hex: "48484C"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var gridView: some View {
        let weeks = stride(from: 0, to: yearDays.count, by: 7).map {
            Array(yearDays[$0..<min($0 + 7, yearDays.count)])
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 2) {
                ForEach(weeks.indices, id: \.self) { weekIndex in
                    VStack(spacing: 2) {
                        ForEach(weeks[weekIndex], id: \.timeIntervalSince1970) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cellColor(for: day))
                                .frame(width: 9, height: 9)
                                .onTapGesture {
                                    selectedDay = day
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var selectedDayTooltip: some View {
        Group {
            if let day = selectedDay {
                selectedDayTooltipContent(day: day)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDay)
    }

    private func selectedDayTooltipContent(day: Date) -> some View {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let amount = yearData[startOfDay] ?? 0

        return HStack(spacing: 8) {
            Text(day, style: .date)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "8A8A8E"))
            Spacer()
            Text(amount > 0 ? formatCurrency(amount) : "No revenue")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(amount > 0 ? Color(hex: "00C896") : Color(hex: "48484C"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "1C1C22"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
        .transition(.opacity.combined(with: .scale))
    }

    private var legendRow: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "48484C"))

            ForEach([0.06, 0.25, 0.5, 0.75, 1.0], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        opacity < 0.1
                            ? Color.white.opacity(opacity)
                            : Color(hex: "00C896").opacity(opacity)
                    )
                    .frame(width: 9, height: 9)
            }

            Text("More")
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "48484C"))

            Spacer()

            Text("\(Calendar.current.component(.year, from: Date()))")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(hex: "48484C"))
        }
    }

    private var yearGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YEAR IN VIEW")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(Color(hex: "48484C"))

            monthLabelsRow

            gridView

            selectedDayTooltip

            legendRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "141418"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var filteredEntries: [RevenueEntry] {
        switch leaderboardPeriod {
        case .thisMonth:
            let cal = Calendar.current
            let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
            return allEntries.filter { ($0.date ?? Date()) >= startOfMonth }
        case .allTime:
            return Array(allEntries)
        }
    }

    private var clientTotals: [ClientTotal] {
        var grouped: [String: (Double, Int)] = [:]
        let entries = filteredEntries
        let grandTotal = entries.reduce(0) { $0 + $1.amount }

        for entry in entries {
            let key: String
            if let raw = entry.label?.trimmingCharacters(in: .whitespaces), !raw.isEmpty {
                key = raw
            } else {
                key = "Untagged"
            }
            grouped[key, default: (0, 0)].0 += entry.amount
            grouped[key, default: (0, 0)].1 += 1
        }

        return grouped
            .map { name, data in
                ClientTotal(
                    id: name,
                    name: name,
                    total: data.0,
                    entryCount: data.1,
                    percentage: grandTotal > 0 ? (data.0 / grandTotal) * 100 : 0
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CLIENT LEADERBOARD")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "48484C"))
                Spacer()
                Text("\(clientTotals.count) clients")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "48484C"))
            }

            HStack(spacing: 0) {
                ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                    Button {
                        leaderboardPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(leaderboardPeriod == period ? .white : Color(hex: "8A8A8E"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(2)
            .background(Color(hex: "1C1C22"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 4)

            if clientTotals.isEmpty {
                VStack(spacing: 8) {
                    Text("👥")
                        .font(.system(size: 28))
                    Text("No client data yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "8A8A8E"))
                    Text("Add a client name when logging payments")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "48484C"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(clientTotals.indices, id: \.self) { index in
                    clientRow(
                        rank: index + 1,
                        client: clientTotals[index],
                        isTop: index == 0
                    )
                }
            }
        }
        .padding(16)
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

    @ViewBuilder
    private func clientRow(rank: Int, client: ClientTotal, isTop: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isTop ? Color(hex: "00C896").opacity(0.15) : Color(hex: "1C1C22"))
                    Text(isTop ? "🥇" : "\(rank)")
                        .font(.system(size: isTop ? 14 : 12, weight: .bold))
                        .foregroundColor(isTop ? Color(hex: "00C896") : Color(hex: "8A8A8E"))
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(client.entryCount) payment\(client.entryCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "48484C"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(client.total))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isTop ? Color(hex: "00C896") : .white)
                    Text("\(Int(client.percentage))%")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "48484C"))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isTop ? Color(hex: "00C896") : Color(hex: "00C896").opacity(0.4))
                        .frame(
                            width: geo.size.width * CGFloat(client.percentage / 100),
                            height: 3
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: client.percentage)
                }
            }
            .frame(height: 3)

            if rank < clientTotals.count {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
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
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
