//
//  ParkAtCUApp.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import SwiftUI

@main
struct ParkAtCUApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                mainApp
                    .tint(AppTheme.primary)
                if showSplash {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
    }

    var mainApp: some View {
        TabView {
//            CurrentView(viewModel: SpotsViewModel())
//                .tabItem { Label("Current", systemImage: "car.fill") }
            CurrentView(viewModel: MockData.previewSpotsViewModel, autoLoad: false)
                .tabItem { Label("Current", systemImage: "car.fill") }

            ForecastView()
                .tabItem { Label("Future", systemImage: "clock") }

            NotificationsView()
                .tabItem { Label("Alerts", systemImage: "bell") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
    }
}
