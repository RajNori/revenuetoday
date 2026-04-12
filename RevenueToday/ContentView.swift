//
//  ContentView.swift
//  RevenueToday
//

import SwiftUI
import CoreData
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(
                        "Today",
                        systemImage: selectedTab == 0 ? "house.fill" : "house"
                    )
                }
                .tag(0)
            HistoryView()
                .tabItem {
                    Label(
                        "History",
                        systemImage: selectedTab == 1 ? "chart.bar.fill" : "chart.bar"
                    )
                }
                .tag(1)
        }
        .tabViewStyle(.automatic)
        .tint(Theme.accent)
        .background(Theme.pageBackground)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(
                red: 20 / 255,
                green: 20 / 255,
                blue: 24 / 255,
                alpha: 1
            )
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
