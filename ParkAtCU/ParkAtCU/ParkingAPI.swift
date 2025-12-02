//
//  ParkingAPI.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import Foundation

class ParkingAPI {
    static let shared = ParkingAPI()

    // TODO: replace this with your real backend base URL
    private let baseURL = URL(string: "https://your-backend-url.com")!

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Fetch current spots near the given coordinates.
    func fetchCurrentSpots(
        lat: Double,
        lng: Double,
        radius: Int = 300
    ) async throws -> [ParkingSpot] {

        var components = URLComponents(url: baseURL.appendingPathComponent("/api/spots/current"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "radius", value: String(radius))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try decoder.decode(CurrentSpotsResponse.self, from: data)
        return decoded.spots
    }
}
