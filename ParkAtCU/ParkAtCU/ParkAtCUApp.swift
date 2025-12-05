//
//  ParkAtCUApp.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import SwiftUI

@main
struct ParkAtCUApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: SpotsViewModel())
                    .tabItem {
                        Label("Current", systemImage: "car.fill")
                    }

                ForecastView()
                    .tabItem {
                        Label("Future", systemImage: "clock.arrow.circlepath")
                    }

                NotificationsView()
                    .tabItem {
                        Label("Alerts", systemImage: "bell.badge")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
        }
    }
}
