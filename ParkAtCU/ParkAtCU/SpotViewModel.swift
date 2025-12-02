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

    func loadSpots() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await ParkingAPI.shared.fetchCurrentSpots(
                    lat: defaultLat,
                    lng: defaultLng,
                    radius: radius
                )
                self.spots = result
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
