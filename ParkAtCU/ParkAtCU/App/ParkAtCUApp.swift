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
                ContentView()
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

}
