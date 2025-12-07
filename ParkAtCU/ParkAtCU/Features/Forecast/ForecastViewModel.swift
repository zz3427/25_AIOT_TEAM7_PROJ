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

    @Published var spots: [ParkingSpot] = []             // Backend result
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
            selectedCoordinate = CLLocationCoordinate2D(latitude: defaultLat,
                                                       longitude: defaultLng)
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
                    self.searchText = String(format: "%.5f, %.5f",
                                             coord.latitude, coord.longitude)
                }

                completion(coord)
            }
        }
    }

    /// Call backend using currently selected coordinate + time.
    func loadForecastForCurrentSelection() async {
        guard let coord = selectedCoordinate else {
            errorMessage = "Choose a location first."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let spots = try await api.fetchForecastSpots(
                lat: coord.latitude,
                lng: coord.longitude,
                radius: defaultRadius,
                time: selectedTime
            )
            self.spots = spots
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}
