//
//  ForecastModels.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/7/25.
//

import Foundation
import CoreLocation

// MARK: - Forecast models for /api/spots/forecast

struct ForecastResponse: Decodable {
    let prediction: ForecastPrediction?
    let query: ForecastQuery
    let spots: [ForecastSpot]
    let summary: ForecastSummary?
    let timestamp: Date?
}

struct ForecastPrediction: Codable {
    let arrivalTimestamp: Date?
    let avgPredictedAvailability: Double?
    let expectedWaitMinutes: Double?
}

struct ForecastQuery: Codable {
    let lat: Double
    let lng: Double
    let radius: Double?
}

struct ForecastSummary: Codable {
    let empty_spots: Int
    let total_spots: Int
}

struct ForecastSpot: Identifiable, Decodable {
    let id: String
    let spotID: String
    let lat: Double
    let lng: Double
    let status: String
    let predictedAvailability: Double?
    let estimatedWaitMinutes: Double?
    let distanceMeters: Double?
    let lastUpdated: Date?
    let sourceCameraID: String?

    enum CodingKeys: String, CodingKey {
        case spotID
        case lat, lng, status
        case predictedAvailability
        case estimatedWaitMinutes
        case distanceMeters
        case lastUpdated
        case sourceCameraID
    }

    // From backend JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spotID = try c.decode(String.self, forKey: .spotID)
        lat = try c.decode(Double.self, forKey: .lat)
        lng = try c.decode(Double.self, forKey: .lng)
        status = try c.decode(String.self, forKey: .status)
        predictedAvailability = try c.decodeIfPresent(Double.self, forKey: .predictedAvailability)
        estimatedWaitMinutes = try c.decodeIfPresent(Double.self, forKey: .estimatedWaitMinutes)
        distanceMeters = try c.decodeIfPresent(Double.self, forKey: .distanceMeters)
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated)
        sourceCameraID = try c.decodeIfPresent(String.self, forKey: .sourceCameraID)

        id = spotID
    }

    // For previews / mocks
    init(
        spotID: String,
        lat: Double,
        lng: Double,
        status: String,
        predictedAvailability: Double? = nil,
        estimatedWaitMinutes: Double? = nil,
        distanceMeters: Double? = nil,
        lastUpdated: Date? = nil,
        sourceCameraID: String? = nil
    ) {
        self.id = spotID
        self.spotID = spotID
        self.lat = lat
        self.lng = lng
        self.status = status
        self.predictedAvailability = predictedAvailability
        self.estimatedWaitMinutes = estimatedWaitMinutes
        self.distanceMeters = distanceMeters
        self.lastUpdated = lastUpdated
        self.sourceCameraID = sourceCameraID
    }
}
