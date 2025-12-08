//
//  Models.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import Foundation

struct SpotNotification: Identifiable, Hashable {
    let id: UUID
    let spotID: String
    let lat: Double
    let lng: Double
    let createdAt: Date
    let cameraID: String?

    var title: String {
        "New empty spot: \(spotID)"
    }
}

struct QueryInfo: Decodable {
    let lat: Double
    let lng: Double
    let radius: Double?   // because backend sends null sometimes
}

struct SpotsResponse: Decodable {
    let query: QueryInfo
    let spots: [ParkingSpot]
    let timestamp: String
}


struct ParkingSpot: Identifiable, Decodable, Hashable {
    let id = UUID()
    let spotID: String
    let lat: Double
    let lng: Double
    let status: String
    let sourceCameraID: String?
    let lastUpdated: Date?
    
    private enum CodingKeys: String, CodingKey {
        case spotID
        case lat
        case lng
        case status
        case sourceCameraID
        case lastUpdated
    }
}

