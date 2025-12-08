//
//  ForecastViewModel.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/4/25.
//

import Foundation
import CoreLocation
import MapKit

@MainActor
final class ForecastViewModel: ObservableObject {

    // MARK: - User inputs / UI state

    @Published var searchText: String = ""               // Address or "lat, lng"
    @Published var selectedTime: Date = Date()           // Future time picker
    @Published var selectedCoordinate: CLLocationCoordinate2D? // From geocode or map drag

    // 🔮 Forecast results (now using ForecastSpot, not ParkingSpot)
    @Published var spots: [ForecastSpot] = []            // Backend result for forecast
    @Published var prediction: ForecastPrediction?       // High-level prediction block
    @Published var summary: ForecastSummary?             // Summary (empty/total)
    
    @Published var isLoading: Bool = false
    @Published var isGeocoding: Bool = false
    @Published var errorMessage: String?

    // MARK: - Defaults / services

    private let api = ParkingAPI.shared
    private let geocoder = CLGeocoder()

    // Columbia default
    let defaultLat: Double = 40.8075
    let defaultLng: Double = -73.9626
    let defaultRadius: Double? = 300

    // MARK: - Public helpers

    func ensureDefaultCoordinate() {
        if selectedCoordinate == nil {
            selectedCoordinate = CLLocationCoordinate2D(
                latitude: defaultLat,
                longitude: defaultLng
            )
            searchText = String(format: "%.5f, %.5f", defaultLat, defaultLng)
        }
    }

    /// Called when the map's region center changes (user drags/zooms).
    func updateFromRegion(_ region: MKCoordinateRegion) {
        selectedCoordinate = region.center
        searchText = String(
            format: "%.5f, %.5f",
            region.center.latitude,
            region.center.longitude
        )
    }

    /// Geocode the typed-in address and recenter the map.
    func geocodeSearch(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(nil)
            return
        }

        isGeocoding = true
        errorMessage = nil

        geocoder.geocodeAddressString(trimmed) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                self.isGeocoding = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                    return
                }

                guard let loc = placemarks?.first?.location else {
                    self.errorMessage = "Could not find that address."
                    completion(nil)
                    return
                }

                let coord = loc.coordinate
                self.selectedCoordinate = coord

                // Also normalize the text to something nice (optional)
                if let name = placemarks?.first?.name,
                   let city = placemarks?.first?.locality {
                    self.searchText = "\(name), \(city)"
                } else {
                    self.searchText = String(
                        format: "%.5f, %.5f",
                        coord.latitude,
                        coord.longitude
                    )
                }

                completion(coord)
            }
        }
    }
    
    func fakeLoadForecastForCurrentSelection() async {
            guard let coord = selectedCoordinate else {
                errorMessage = "Choose a location first."
                return
            }

            isLoading = true
            errorMessage = nil

            // 👇 DEMO LOG: just to show we “used” the coordinate + time
            print("Demo forecast for lat=\(coord.latitude), lng=\(coord.longitude), time=\(selectedTime)")

            // Use mock spots instead of api.fetchForecast(...)
            let sorted = ForecastMockData.spots.sorted { lhs, rhs in
                let l = lhs.estimatedWaitMinutes ?? .greatestFiniteMagnitude
                let r = rhs.estimatedWaitMinutes ?? .greatestFiniteMagnitude
                return l < r
            }

            self.spots = sorted
            self.isLoading = false

            // If you want, you can also fake a prediction/summary:
            // self.prediction = ForecastPrediction(
            //     arrivalTimestamp: Date().addingTimeInterval(4 * 60),
            //     avgPredictedAvailability: 0.85,
            //     expectedWaitMinutes: 4.0
            // )
            // self.summary = ForecastSummary(empty_spots: 2, total_spots: 3)
        }

    /// Call backend using currently selected coordinate + time.
    /// Uses the forecast endpoint and sorts by estimated wait time.
    func loadForecastForCurrentSelection() async {
        guard let coord = selectedCoordinate else {
            errorMessage = "Choose a location first."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.fetchForecast(
                lat: coord.latitude,
                lng: coord.longitude,
                radius: defaultRadius,
                time: selectedTime
            )

            // Debug: print out the waits we got
            let waits = response.spots.map { $0.estimatedWaitMinutes ?? -1 }
            print("Forecast waits from backend:", waits)

            // Sort by estimated wait ascending (nil -> bottom)
            let sorted = response.spots.sorted { lhs, rhs in
                let l = lhs.estimatedWaitMinutes ?? .greatestFiniteMagnitude
                let r = rhs.estimatedWaitMinutes ?? .greatestFiniteMagnitude
                return l < r
            }

            self.spots = sorted   // 👈 keep the sorted list
            self.isLoading = false
        } catch {
            print("Forecast error:", error)
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

////
////  ForecastViewModel.swift
////  ParkAtCU
////
////  Created by Gerald Zhao on 12/4/25.
////
//
//import Foundation
//import CoreLocation
//import MapKit
//
//@MainActor
//final class ForecastViewModel: ObservableObject {
//
//    // MARK: - User inputs / UI state
//
//    @Published var searchText: String = ""               // Address or "lat, lng"
//    @Published var selectedTime: Date = Date()           // Future time picker
//    @Published var selectedCoordinate: CLLocationCoordinate2D? // From geocode or map drag
//
//    @Published var spots: [ParkingSpot] = []             // Backend result
//    @Published var isLoading: Bool = false
//    @Published var isGeocoding: Bool = false
//    @Published var errorMessage: String?
//
//    // MARK: - Defaults / services
//
//    private let api = ParkingAPI.shared
//    private let geocoder = CLGeocoder()
//
//    // Columbia default
//    let defaultLat: Double = 40.8075
//    let defaultLng: Double = -73.9626
//    let defaultRadius: Double? = 300
//
//    // MARK: - Public helpers
//
//    func ensureDefaultCoordinate() {
//        if selectedCoordinate == nil {
//            selectedCoordinate = CLLocationCoordinate2D(latitude: defaultLat,
//                                                       longitude: defaultLng)
//            searchText = String(format: "%.5f, %.5f", defaultLat, defaultLng)
//        }
//    }
//
//    /// Called when the map's region center changes (user drags/zooms).
//    func updateFromRegion(_ region: MKCoordinateRegion) {
//        selectedCoordinate = region.center
//        searchText = String(
//            format: "%.5f, %.5f",
//            region.center.latitude,
//            region.center.longitude
//        )
//    }
//
//    /// Geocode the typed-in address and recenter the map.
//    func geocodeSearch(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
//        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else {
//            completion(nil)
//            return
//        }
//
//        isGeocoding = true
//        errorMessage = nil
//
//        geocoder.geocodeAddressString(trimmed) { [weak self] placemarks, error in
//            Task { @MainActor in
//                guard let self else { return }
//                self.isGeocoding = false
//
//                if let error {
//                    self.errorMessage = error.localizedDescription
//                    completion(nil)
//                    return
//                }
//
//                guard let loc = placemarks?.first?.location else {
//                    self.errorMessage = "Could not find that address."
//                    completion(nil)
//                    return
//                }
//
//                let coord = loc.coordinate
//                self.selectedCoordinate = coord
//
//                // Also normalize the text to something nice (optional)
//                if let name = placemarks?.first?.name,
//                   let city = placemarks?.first?.locality {
//                    self.searchText = "\(name), \(city)"
//                } else {
//                    self.searchText = String(format: "%.5f, %.5f",
//                                             coord.latitude, coord.longitude)
//                }
//
//                completion(coord)
//            }
//        }
//    }
//
//    /// Call backend using currently selected coordinate + time.
//    func loadForecastForCurrentSelection() async {
//        guard let coord = selectedCoordinate else {
//            errorMessage = "Choose a location first."
//            return
//        }
//
//        isLoading = true
//        errorMessage = nil
//
//        do {
//            let spots = try await api.fetchForecastSpots(
//                lat: coord.latitude,
//                lng: coord.longitude,
//                radius: defaultRadius,
//                time: selectedTime
//            )
//            self.spots = spots
//            self.isLoading = false
//        } catch {
//            self.isLoading = false
//            self.errorMessage = error.localizedDescription
//        }
//    }
//}
