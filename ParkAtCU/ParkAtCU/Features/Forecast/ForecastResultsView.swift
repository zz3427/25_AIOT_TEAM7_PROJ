//
//  ForecastResultsView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/6/25.
//
import SwiftUI
import CoreLocation

// TODO: sort by estimated wait time? show in a map with pins being number? wait time? click on each to navigate?
struct ForecastResultsView: View {
    @ObservedObject var viewModel: ForecastViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading forecast…")
                    .font(.headline)
                Spacer()

            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Text("Error")
                        .font(.title2).bold()
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()

            } else if viewModel.spots.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("No forecast available")
                        .font(.title2).bold()
                    Text("Try another time or location.")
                        .foregroundColor(.secondary)
                }
                Spacer()

            } else {
                List(viewModel.spots) { spot in
                    ForecastResultRow(spot: spot)
                }
            }
        }
        .padding(.top)
        .navigationTitle("Forecast Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ForecastResultRow: View {
    let spot: ParkingSpot

    private func timeAgoString(from date: Date?) -> String {
        guard let date else { return "Unknown time" }
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 { return "Just now" }
        if minutes == 1 { return "1 minute ago" }
        return "\(minutes) minutes ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text(spot.spotID)
                    .font(.headline)
                Spacer()
                Text(spot.status.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }

            Text(String(format: "Lat: %.5f, Lng: %.5f", spot.lat, spot.lng))
                .font(.caption)
                .foregroundColor(.secondary)

            if let updated = spot.lastUpdated {
                Text("Updated: \(timeAgoString(from: updated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        spot.status.lowercased() == "empty" ? .green : .red
    }
}

@MainActor
struct ForecastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        // Build a mock view model ON the main actor
        let vm = ForecastViewModel()
        vm.selectedTime = Date().addingTimeInterval(15 * 60) // 15 min in the future
        vm.selectedCoordinate = CLLocationCoordinate2D(
            latitude: 40.8075,
            longitude: -73.9626
        )

        vm.spots = [
            ParkingSpot(
                spotID: "A201",
                lat: 40.8078,
                lng: -73.9623,
                status: "empty",
                sourceCameraID: "cam-2",
                lastUpdated: Date().addingTimeInterval(-180) // 3 min ago
            ),
            ParkingSpot(
                spotID: "A202",
                lat: 40.8079,
                lng: -73.9624,
                status: "occupied",
                sourceCameraID: "cam-2",
                lastUpdated: Date().addingTimeInterval(-420) // 7 min ago
            )
        ]

        return NavigationStack {
            ForecastResultsView(viewModel: vm)
        }
        .environment(\.colorScheme, .light)
    }
}
