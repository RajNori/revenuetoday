//
//  Persistence.swift
//  RevenueToday
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for i in 0..<3 {
            let entry = RevenueEntry(context: viewContext)
            entry.id = UUID()
            entry.amount = Double(100 * (i + 1))
            entry.label = i == 0 ? "Sample" : nil
            entry.date = cal.date(byAdding: .hour, value: i * 2, to: today) ?? today
            entry.createdAt = entry.date
        }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Preview save failed: \(error)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RevenueToday")
        if inMemory {
            if let desc = container.persistentStoreDescriptions.first {
                desc.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                assertionFailure("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension NSManagedObjectContext {
    func entriesForToday() throws -> [RevenueEntry] {
        let request = NSFetchRequest<RevenueEntry>(entityName: "RevenueEntry")
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else {
            return []
        }
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RevenueEntry.date, ascending: false)]
        return try fetch(request)
    }

    func todayTotal() -> Double {
        do {
            return try entriesForToday().reduce(0) { $0 + $1.amount }
        } catch {
            return 0
        }
    }

    func thisMonthTotal() -> Double {
        do {
            let cal = Calendar.current
            let now = Date()
            let comps = cal.dateComponents([.year, .month], from: now)
            guard let start = cal.date(from: comps),
                  let end = cal.date(byAdding: .month, value: 1, to: start)
            else {
                return 0
            }
            return try entries(from: start, toExclusive: end).reduce(0) { $0 + $1.amount }
        } catch {
            return 0
        }
    }

    func entriesForMonth(date: Date) throws -> [RevenueEntry] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let start = cal.date(from: comps),
              let end = cal.date(byAdding: .month, value: 1, to: start)
        else {
            return []
        }
        return try entries(from: start, toExclusive: end)
    }

    func dailyTotals(days: Int) -> [(Date, Double)] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        var result: [(Date, Double)] = []
        for offset in (0..<days).reversed() {
            guard let dayStart = cal.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            guard let next = cal.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let sum: Double
            do {
                sum = try entries(from: dayStart, toExclusive: next).reduce(0) { $0 + $1.amount }
            } catch {
                sum = 0
            }
            result.append((dayStart, sum))
        }
        return result
    }

    private func entries(from start: Date, toExclusive end: Date) throws -> [RevenueEntry] {
        let request = NSFetchRequest<RevenueEntry>(entityName: "RevenueEntry")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RevenueEntry.date, ascending: false)]
        return try fetch(request)
    }
}

extension RevenueEntry {
    static func todayFetchRequest() -> NSFetchRequest<RevenueEntry> {
        let request = NSFetchRequest<RevenueEntry>(entityName: "RevenueEntry")
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RevenueEntry.date, ascending: false)]
        return request
    }
}
