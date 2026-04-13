//
//  RevenueTodayApp.swift
//  RevenueToday
//

import SwiftUI
import CoreData

@main
struct RevenueTodayApp: App {
    let persistenceController = PersistenceController.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
