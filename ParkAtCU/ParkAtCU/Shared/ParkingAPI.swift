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

enum ParkingAPIError: Error {
    case badURL
    case badResponse
}

final class ParkingAPI {
    static let shared = ParkingAPI()

    // NOTICE:
    // - Simulator talking to backend on SAME Mac: use 127.0.0.1
    // - Real iPhone on same Wi-Fi: change this to LAN IP, e.g. "http://192.168.1.208:8080"
    private let baseURL = URL(string: "http://127.0.0.1:8080")!
//    private let baseURL = URL(string: "http://10.206.110.154:8080")!

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

    private static let iso8601Fractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()

        private func makeDecoder() -> JSONDecoder {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)

                // Try full ISO8601 with fractional seconds
                if let date = ParkingAPI.iso8601Fractional.date(from: str) {
                    return date
                }

                // Fallback: regular ISO8601
                if let date = ISO8601DateFormatter().date(from: str) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO8601 date: \(str)"
                )
            }
            return decoder
        }

        // MARK: - Forecast endpoint

        func fetchForecast(
            lat: Double,
            lng: Double,
            radius: Double?,
            time: Date
        ) async throws -> ForecastResponse {
            var components = URLComponents(
                url: baseURL.appendingPathComponent("/api/spots/forecast"),
                resolvingAgainstBaseURL: false
            )

            var items: [URLQueryItem] = [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lng", value: String(lng))
            ]
            if let radius {
                items.append(URLQueryItem(name: "radius", value: String(radius)))
            }

            // If backend later wants a time parameter, add:
            // let iso = ParkingAPI.iso8601Fractional.string(from: time)
            // items.append(URLQueryItem(name: "time", value: iso))

            components?.queryItems = items

            guard let url = components?.url else {
                throw ParkingAPIError.badURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw ParkingAPIError.badResponse
            }

            #if DEBUG
            // Helpful to see raw JSON when debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Forecast raw JSON:\n\(jsonString)")
            }
            #endif

            let decoder = makeDecoder()
            return try decoder.decode(ForecastResponse.self, from: data)
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
        // ISO8601 with fractional seconds to match backend style
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter.string(from: date)
    }
}
