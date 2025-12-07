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

//
//
//// Response from GET /api/spots/current
//struct CurrentSpotsResponse: Decodable {
//    let query: QueryInfo
//    let spots: [ParkingSpot]
//    let timestamp: String
//
//}
//
//struct QueryInfo: Decodable {
//    let lat: Double
//    let lng: Double
//    let radius: Double?    // 👈 must be optional because backend sends null
//
//    // No CodingKeys needed because names match JSON: lat, lng, radius
//}
//
////struct QueryInfo: Decodable {
////    let lat: Double?
////    let lng: Double?
////    let radius: Int?
////    let lotID: String?
////
////    enum CodingKeys: String, CodingKey {
////        case lat, lng, radius
////        case lotID = "lot_id"
////    }
////}
//
////struct ParkingSpot: Identifiable, Decodable {
////    var id: String { spotID }  // for SwiftUI List
////
////    let spotID: String
////    let lat: Double
////    let lng: Double
////    let status: String
////    let sourceCameraID: String?
////    let lastUpdated: Date?
////
////    enum CodingKeys: String, CodingKey {
////        case spotID = "spot_id"
////        case lat, lng, status
////        case sourceCameraID = "source_camera_id"
////        case lastUpdated = "last_updated"
////    }
////}
//
//struct ParkingSpot: Identifiable, Decodable {
//    let id = UUID()                // 👈 not in JSON, we synthesize it
//    let spotID: String
//    let lat: Double
//    let lng: Double
//    let status: String
//    let sourceCameraID: String?
//    let lastUpdated: Date?
//
//    private enum CodingKeys: String, CodingKey {
//        case spotID
//        case lat
//        case lng
//        case status
//        case sourceCameraID
//        case lastUpdated
//    }
//}
//
//struct ForecastSpotsResponse: Decodable {
//    let timestamp: String?
//    let query: QueryInfo?
//    let spots: [ParkingSpot]
//    let forecastFor: String?       // e.g. ISO time string
//    let confidence: Double?        // optional, 0..1
//}
