//
//  ParkingAPI.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import Foundation
import Combine

import Foundation

final class ParkingAPI {
    static let shared = ParkingAPI()
    private init() {}

    // TODO: replace with your actual laptop IP
    private let baseURL = URL(string: "http://192.168.1.208:8080")!  // e.g. http://192.168.1.208:8080

    /// Fetch current spots from the backend, filtered by lat/lng/radius if the backend uses them.
    func fetchCurrentSpots(
        lat: Double,
        lng: Double,
        radius: Int
    ) async throws -> [ParkingSpot] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/api/spots/current"),
            resolvingAgainstBaseURL: false
        )!

        // These can be ignored by the backend for now if you haven't wired them yet
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "radius", value: String(radius))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        // Your backend returns ISO-8601 timestamps like "2025-12-01T21:30:45Z",
        // so this will decode `lastUpdated: Date?` correctly.
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(CurrentSpotsResponse.self, from: data)
        return decoded.spots
    }
    
    func fetchForecastSpots(
            timeISO8601: String,
            lat: Double,
            lng: Double,
            radius: Int
        ) async throws -> ForecastSpotsResponse {
            
            let isoTime = ISO8601DateFormatter().string(from: Date())
            
            return ForecastSpotsResponse(
                timestamp: isoTime,
                query: nil,
                spots: [
                    ParkingSpot(
                        spotID: "spot-201",
                        lat: 40.8085,
                        lng: -73.9619,
                        status: "empty",
                        sourceCameraID: "cam-001",
                        lastUpdated: Date()
                    )
                ],
                forecastFor: timeISO8601,
                confidence: 0.8
            )
            
//            var components = URLComponents(
//                url: baseURL.appendingPathComponent("/api/spots/forecast"),
//                resolvingAgainstBaseURL: false
//            )!
//
//            components.queryItems = [
//                URLQueryItem(name: "time", value: timeISO8601),
//                URLQueryItem(name: "lat", value: String(lat)),
//                URLQueryItem(name: "lng", value: String(lng)),
//                URLQueryItem(name: "radius", value: String(radius))
//            ]
//
//            guard let url = components.url else {
//                throw URLError(.badURL)
//            }
//
//            let (data, response) = try await URLSession.shared.data(from: url)
//
//            if let http = response as? HTTPURLResponse,
//               !(200...299).contains(http.statusCode) {
//                throw URLError(.badServerResponse)
//            }
//
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .iso8601
//
//            return try decoder.decode(ForecastSpotsResponse.self, from: data)
        }
}
