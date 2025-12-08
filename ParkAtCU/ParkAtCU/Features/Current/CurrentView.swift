import SwiftUI
import MapKit

private struct MapItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind

    enum Kind {
        case spot(ParkingSpot)
        case user
    }
}

struct CurrentView: View {
    @StateObject private var viewModel: SpotsViewModel
    @StateObject private var locationManager = LocationManager()
    private let autoLoad: Bool

    init(viewModel: SpotsViewModel, autoLoad: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.autoLoad = autoLoad
    }

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8075, longitude: -73.9626), // default: Columbia
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationStack {
            mapLayer
//                .ignoresSafeArea()   // map goes under status bar / island / home bar
                .toolbar {
                    // Center title
                    ToolbarItem(placement: .principal) {
                        Text("Current Empty Spots")
                            .font(.title.bold())
                    }

                    // Refresh button on the right
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.loadSpots()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                        }
                    }
                }
        }
        .toolbarBackground(AppTheme.primary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            if autoLoad {
                viewModel.loadSpots()
            }
        }
        .onChange(of: locationManager.lastLocation) { newLocation in
            if let loc = newLocation {
                region.center = loc.coordinate
            }
        }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        let emptySpots = viewModel.spots.filter {
            $0.status.lowercased() == "empty"
        }

        // Build annotation items: spots + (optional) user location
        var items: [MapItem] = emptySpots.map { spot in
            MapItem(
                id: "spot-\(spot.spotID)",   // stable per spot
                coordinate: CLLocationCoordinate2D(latitude: spot.lat, longitude: spot.lng),
                kind: .spot(spot)
            )
        }

        if let userLocation = locationManager.lastLocation {
            items.append(
                MapItem(
                    id: "user-location",     // always the same id
                    coordinate: userLocation.coordinate,
                    kind: .user
                )
            )
        }

        return ZStack {
            Map(coordinateRegion: $region, annotationItems: items) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item.kind {
                    case .spot(let spot):
                        Button {
                            openInMaps(spot)
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(AppTheme.primary)
                                Text(spot.spotID)
                                    .font(.caption2)
                                    .padding(3)
                                    .background(.thinMaterial)
                                    .cornerRadius(4)
                            }
                        }

                    case .user:
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(radius: 4)
                    }
                }
            }
            .ignoresSafeArea()

            // Center overlays for states
            if viewModel.isLoading {
                overlayCard(
                    title: "Loading spots…",
                    message: nil
                )
            } else if let error = viewModel.errorMessage {
                overlayCard(
                    title: "Error",
                    message: error
                )
            } else if emptySpots.isEmpty {
                overlayCard(
                    title: "No empty spots found",
                    message: "Try again or adjust query radius on the backend."
                )
            }

            // Small hint while no user location yet
            if locationManager.lastLocation == nil {
                VStack {
                    Text("Locating you…")
                        .font(.caption)
                        .padding(6)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(.top, 60)
            }

            // 🔔 Watch button pinned at the bottom
            VStack {
                Spacer()
                watchButton
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Watch button

    private var watchButton: some View {
        Button {
            if viewModel.isWatching {
                viewModel.stopWatch()
            } else {
                viewModel.startWatch()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isWatching ? "bell.slash.fill" : "bell.badge.fill")

                if viewModel.isWatching, let expiry = viewModel.watchExpiresAt {
                    Text("Watching… \(timeRemainingString(until: expiry))")
                } else {
                    Text("Watch for spot (15 min)")
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(AppTheme.primary)
            .cornerRadius(24)
            .shadow(radius: 4)
        }
    }

    private func timeRemainingString(until date: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSinceNow))
        let minutes = remaining / 60
        let seconds = remaining % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }

    private func overlayCard(title: String, message: String?) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Open in Apple Maps

    private func openInMaps(_ spot: ParkingSpot) {
        let coordinate = CLLocationCoordinate2D(latitude: spot.lat, longitude: spot.lng)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.spotID

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// Optional list UI
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
                Text("Updated \(updated, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CurrentView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentView(
            viewModel: MockData.previewSpotsViewModel,
            autoLoad: false
        )
    }
}
