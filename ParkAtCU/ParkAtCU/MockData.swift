//
//  MockData.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//
import Foundation

enum MockData {
    static let sampleSpots: [ParkingSpot] = [
        ParkingSpot(
            spotID: "spot-101",
            lat: 40.8080,
            lng: -73.9620,
            status: "empty",
            sourceCameraID: "cam-001",
            lastUpdated: Date()
        ),
        ParkingSpot(
            spotID: "spot-102",
            lat: 40.8078,
            lng: -73.9624,
            status: "occupied",
            sourceCameraID: "cam-001",
            lastUpdated: Date()
        ),
        ParkingSpot(
            spotID: "spot-103",
            lat: 40.8076,
            lng: -73.9628,
            status: "empty",
            sourceCameraID: "cam-002",
            lastUpdated: Date()
        )
    ]

    /// A SpotsViewModel pre-populated with sample data for previews
    @MainActor
    static var previewSpotsViewModel: SpotsViewModel {
        let vm = SpotsViewModel()
        vm.isLoading = false
        vm.errorMessage = nil
        vm.spots = sampleSpots
        return vm
    }
}
