//
//  ForecastViewModel.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/4/25.
//

import Foundation

@MainActor
class ForecastViewModel: ObservableObject {
    @Published var spots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTime: Date = Date().addingTimeInterval(30 * 60) // 30 min ahead

    private let api = ParkingAPI.shared

    // You can reuse the same defaults as SpotsViewModel or customize
    private let defaultLat = 40.8075
    private let defaultLng = -73.9626
    private let radius = 300

    func loadForecast() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let isoTime = iso8601String(from: selectedTime)
                let response = try await api.fetchForecastSpots(
                    timeISO8601: isoTime,
                    lat: defaultLat,
                    lng: defaultLng,
                    radius: radius
                )
                self.spots = response.spots
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func iso8601String(from date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }
}
