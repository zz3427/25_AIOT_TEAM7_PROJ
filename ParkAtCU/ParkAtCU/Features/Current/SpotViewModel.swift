//
//  SpotViewModel.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import Foundation

@MainActor
class SpotsViewModel: ObservableObject {
    @Published var spots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // For now, hard-code a location (e.g. Columbia campus) for testing.
    // Later you can replace this with CoreLocation.
    private let defaultLat = 40.8075
    private let defaultLng = -73.9626
    private let radius = 300
    
    private let appState: AppState?
    init(appState: AppState? = nil) {
        self.appState = appState
    }

    func loadSpots() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await ParkingAPI.shared.fetchCurrentSpots(
                    lat: defaultLat,
                    lng: defaultLng,
                    radius: Double(radius)
                )
                self.spots = result
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    @Published var isWatching = false
    @Published var watchExpiresAt: Date?
    @Published var lastEmptySpotIDs: Set<String> = []

    private var watchTask: Task<Void, Never>?

    func startWatch(duration: TimeInterval = 15 * 60) {
        isWatching = true
        watchExpiresAt = Date().addingTimeInterval(duration)
        lastEmptySpotIDs = Set(spots.filter { $0.status.lowercased() == "empty" }.map(\.spotID))

        watchTask?.cancel()
        watchTask = Task {
            await self.runWatchLoop()
        }
    }

    func stopWatch() {
        isWatching = false
        watchExpiresAt = nil
        watchTask?.cancel()
        watchTask = nil
    }

    private func runWatchLoop() async {
        while isWatching, let expires = watchExpiresAt, Date() < expires {
            // Reuse your existing loadSpots() function
            await loadSpots()

            // Compute newly empty spots
            let currentEmpty = Set(spots
                .filter { $0.status.lowercased() == "empty" }
                .map(\.spotID)
            )
            let newlyEmpty = currentEmpty.subtracting(lastEmptySpotIDs)

            if !newlyEmpty.isEmpty {
                await MainActor.run {
                    self.lastEmptySpotIDs = currentEmpty

                    if let firstID = newlyEmpty.first,
                       let spot = self.spots.first(where: { $0.spotID == firstID }) {
                        // 🔔 create notification + banner
                        self.appState?.addNotification(for: spot)
                    }

                    self.stopWatch()  // auto-disarm after success
                }
                break
            }

            // wait a bit before next poll (e.g. 10 seconds)
            try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
        }

        await MainActor.run {
            self.stopWatch()
        }
    }
    
}
