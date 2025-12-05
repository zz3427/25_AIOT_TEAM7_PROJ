//
//  Models.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import Foundation

// Response from GET /api/spots/current
struct CurrentSpotsResponse: Decodable {
    let timestamp: String?
    let query: QueryInfo?
    let spots: [ParkingSpot]
}

struct QueryInfo: Decodable {
    let lat: Double?
    let lng: Double?
    let radius: Int?
    let lotID: String?

    enum CodingKeys: String, CodingKey {
        case lat, lng, radius
        case lotID = "lot_id"
    }
}

struct ParkingSpot: Identifiable, Decodable {
    var id: String { spotID }  // for SwiftUI List

    let spotID: String
    let lat: Double
    let lng: Double
    let status: String
    let sourceCameraID: String?
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case spotID = "spot_id"
        case lat, lng, status
        case sourceCameraID = "source_camera_id"
        case lastUpdated = "last_updated"
    }
}

struct ForecastSpotsResponse: Decodable {
    let timestamp: String?
    let query: QueryInfo?
    let spots: [ParkingSpot]
    let forecastFor: String?       // e.g. ISO time string
    let confidence: Double?        // optional, 0..1
}
