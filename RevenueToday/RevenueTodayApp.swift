//
//  RevenueTodayApp.swift
//  RevenueToday
//
//  Created by Raj on 12/4/2026.
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
        }
    }
}
