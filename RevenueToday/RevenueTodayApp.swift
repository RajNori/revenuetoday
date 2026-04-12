//
//  RevenueTodayApp.swift
//  RevenueToday
//

import SwiftUI
import CoreData

@main
struct RevenueTodayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
