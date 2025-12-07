//
//  ParkingAPI.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//


import Foundation

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class ParkingAPI {
    static let shared = ParkingAPI()

    // IMPORTANT:
    // - Simulator talking to backend on SAME Mac: use 127.0.0.1
    // - Real iPhone on same Wi-Fi: change this to your Mac's LAN IP, e.g. "http://192.168.1.208:8080"
    private let baseURL = URL(string: "http://127.0.0.1:8080")!

    private let decoder: JSONDecoder
    private let session: URLSession

    init() {
        let decoder = JSONDecoder()

        // Custom ISO8601 with fractional seconds to match
        // "2025-12-05T22:36:38.752055Z"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Fallback: try plain ISO8601 without fractional seconds
            if let fallback = ISO8601DateFormatter().date(from: dateString) {
                return fallback
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(dateString)"
            )
        }

        self.decoder = decoder
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Public APIs

    /// Get current spots near a lat/lng within a radius (meters or whatever your backend expects).
    func fetchCurrentSpots(
        lat: Double,
        lng: Double,
        radius: Double?
    ) async throws -> [ParkingSpot] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]

        if let radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }

        let url = try makeURL(path: "/api/spots/current", queryItems: queryItems)
        let data = try await performRequest(url: url)

        let wrapper = try decodeSpotsResponse(from: data)
        return wrapper.spots
    }

    /// Get forecasted spots near a lat/lng for a given future time.
    /// Assumes backend endpoint /api/spots/forecast?lat=..&lng=..&time=ISO8601
    func fetchForecastSpots(
        lat: Double,
        lng: Double,
        radius: Double?,
        time: Date
    ) async throws -> [ParkingSpot] {
        let iso = iso8601String(from: time)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "time", value: iso)
        ]

        if let radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }

        let url = try makeURL(path: "/api/spots/forecast", queryItems: queryItems)
        let data = try await performRequest(url: url)

        let wrapper = try decodeSpotsResponse(from: data)   // SpotsResponse from Models.swift
        return wrapper.spots
    }

    // MARK: - Helpers

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError(message: "Invalid URL for path: \(path)")
        }
        return url
    }

    private func performRequest(url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "Invalid response")
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            print("Server error \(http.statusCode): \(body)")
            throw APIError(message: "Server error \(http.statusCode)")
        }

        // Debug: raw JSON if needed
        // let raw = String(data: data, encoding: .utf8) ?? "<non-UTF8 data>"
        // print("Raw JSON from \(url.path):\n\(raw)")

        return data
    }

    private func decodeSpotsResponse(from data: Data) throws -> SpotsResponse {
        do {
            return try decoder.decode(SpotsResponse.self, from: data)
        } catch {
            print("Decoding error:", error)
            throw error
        }
    }

    private func iso8601String(from date: Date) -> String {
        // ISO8601 with fractional seconds to match your backend style
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter.string(from: date)
    }
}
