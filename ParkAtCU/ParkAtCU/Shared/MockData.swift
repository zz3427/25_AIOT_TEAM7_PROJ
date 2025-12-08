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

enum ForecastMockData {
    static let spots: [ForecastSpot] = [
        ForecastSpot(
            spotID: "cam-001-spot-3",
            lat: 40.810134,
            lng: -73.960933,
            status: "occupied",
            predictedAvailability: 0.85,
            estimatedWaitMinutes: 2.0,
            distanceMeters: 120.0,
            lastUpdated: Date().addingTimeInterval(-60),
            sourceCameraID: "cam-001"
        ),
        ForecastSpot(
            spotID: "cam-001-spot-4",
            lat: 40.810253,
            lng: -73.961215,
            status: "empty",
            predictedAvailability: 0.9,
            estimatedWaitMinutes: 5.0,
            distanceMeters: 200.0,
            lastUpdated: Date().addingTimeInterval(-180),
            sourceCameraID: "cam-001"
        ),
        ForecastSpot(
            spotID: "cam-001-spot-0",
            lat: 40.809591,
            lng: -73.959638,
            status: "empty",
            predictedAvailability: 0.7,
            estimatedWaitMinutes: 15.0,
            distanceMeters: 340.0,
            lastUpdated: Date().addingTimeInterval(-600),
            sourceCameraID: "cam-001"
        )
    ]
}
