//
//  ForecastResultsView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/6/25.
//
import SwiftUI
import MapKit

struct ForecastResultsView: View {
    @ObservedObject var viewModel: ForecastViewModel

    var body: some View {
        List(viewModel.spots) { spot in
            Button {
                openInMaps(spot)
            } label: {
                ForecastResultRow(spot: spot)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Forecast Results")
    }

    private func openInMaps(_ spot: ForecastSpot) {
        let coord = CLLocationCoordinate2D(latitude: spot.lat, longitude: spot.lng)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        item.name = spot.spotID
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct ForecastResultRow: View {
    let spot: ForecastSpot

    private var availabilityText: String {
        if let p = spot.predictedAvailability {
            return String(format: "%.0f%% likely empty", p * 100)
        } else {
            return "Prediction unavailable"
        }
    }

    private var waitMinutes: Double? {
        spot.estimatedWaitMinutes
    }

    private var waitChipText: String {
        guard let w = waitMinutes else { return "Wait: unknown" }
        if w <= 0.5 {
            return "Est. wait: now"
        } else {
            return "Est. wait: \n  ~\(Int(w)) min"
        }
    }

    private var waitChipColor: Color {
        guard let w = waitMinutes else { return .gray }
        switch w {
        case ..<3:
            return .green
        case 3..<8:
            return .orange
        default:
            return .red
        }
    }

    private var distanceText: String {
        if let d = spot.distanceMeters {
            if d < 1000 {
                return String(format: "%.0f m away", d)
            } else {
                return String(format: "%.1f km away", d / 1000)
            }
        } else {
            return "Distance: unknown"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .padding(.vertical, 4)
                .shadow(radius: 2)
                .font(.title3)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(spot.spotID)
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text(availabilityText)
                        .font(.subheadline)
                    
                    HStack(spacing: 8) {
                        Text(distanceText)
                        Text("•")
                        Text(spot.status.capitalized)  // keep raw status as small text
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if let updated = spot.lastUpdated {
                        Text("Updated \(updated, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Text(waitChipText)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(waitChipColor.opacity(0.15))
                    .foregroundColor(waitChipColor)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct ForecastResultsView_Previews: PreviewProvider {
    @MainActor
    static func makeMockViewModel() -> ForecastViewModel {
        let vm = ForecastViewModel()

        vm.spots = [
            ForecastSpot(
                spotID: "cam-001-spot-3",
                lat: 40.810134,
                lng: -73.960933,
                status: "occupied",
                predictedAvailability: 0.85,
                estimatedWaitMinutes: 2.0,
                distanceMeters: 120.0,
                lastUpdated: Date().addingTimeInterval(-60),
                sourceCameraID: "cam-001"
            ),
            ForecastSpot(
                spotID: "cam-001-spot-4",
                lat: 40.810253,
                lng: -73.961215,
                status: "empty",
                predictedAvailability: 0.9,
                estimatedWaitMinutes: 5.0,
                distanceMeters: 200.0,
                lastUpdated: Date().addingTimeInterval(-180),
                sourceCameraID: "cam-001"
            ),
            ForecastSpot(
                spotID: "cam-001-spot-0",
                lat: 40.809591,
                lng: -73.959638,
                status: "empty",
                predictedAvailability: 0.7,
                estimatedWaitMinutes: 15.0,
                distanceMeters: 340.0,
                lastUpdated: Date().addingTimeInterval(-600),
                sourceCameraID: "cam-001"
            )
        ]

        return vm
    }

    @MainActor
    static var previews: some View {
        let vm = makeMockViewModel()

        return NavigationStack {
            ForecastResultsView(viewModel: vm)
        }
        .environment(\.colorScheme, .light)
    }
}
