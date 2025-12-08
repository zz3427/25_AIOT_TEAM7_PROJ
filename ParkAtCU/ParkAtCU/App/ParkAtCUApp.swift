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
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .tint(AppTheme.primary)
                    .environmentObject(appState)
                if showSplash {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        showSplash = false
                    }
                }
            }
        }
    }

}
