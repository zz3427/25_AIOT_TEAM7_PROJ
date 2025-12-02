//
//  ContentView.swift
//  ParkAtCU
//
//  Created by admin on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SpotsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading spots…")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            viewModel.loadSpots()
                        }
                        .padding(.top, 8)
                    }
                } else if viewModel.spots.isEmpty {
                    VStack(spacing: 8) {
                        Text("No spots found")
                            .font(.headline)
                        Text("Try again or adjust your query radius on the backend.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.spots) { spot in
                        SpotRow(spot: spot)
                    }
                }
            }
            .navigationTitle("Current Empty Spots")
            .toolbar {
                Button {
                    viewModel.loadSpots()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.loadSpots()
        }
    }
}

struct SpotRow: View {
    let spot: ParkingSpot

    var statusColor: Color {
        spot.status.lowercased() == "empty" ? .green : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(spot.spotID)
                    .font(.headline)
                Spacer()
                Text(spot.status.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }

            Text(String(format: "Lat: %.5f, Lng: %.5f", spot.lat, spot.lng))
                .font(.caption)
                .foregroundColor(.secondary)

            if let updated = spot.lastUpdated {
                Text("Updated: \(formatted(date: updated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatted(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

