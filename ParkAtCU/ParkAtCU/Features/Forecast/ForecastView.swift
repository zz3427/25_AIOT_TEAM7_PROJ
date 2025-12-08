//
//  ForecastView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/4/25.
//

import SwiftUI
import MapKit

struct ForecastView: View {
    @StateObject private var viewModel = ForecastViewModel()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8075, longitude: -73.9626),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var showResults = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Address entry
                    Text("Where do you want to park?")
                        .font(.headline)

                    HStack {
                        TextField("Enter address or drag the map…",
                                  text: $viewModel.searchText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)

                        if viewModel.isGeocoding {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Button {
                                viewModel.geocodeSearch { coord in
                                    guard let coord else { return }
                                    region.center = coord
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // MARK: Time picker
                    Text("When?")
                        .font(.headline)

                    DatePicker(
                        "Forecast time",
                        selection: $viewModel.selectedTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)

                    // MARK:  Mini map with center pin
                    Text("Adjust on map")
                        .font(.headline)

                    ZStack {
                        Map(coordinateRegion: $region)
                            .frame(height: 260)
                            .cornerRadius(16)
                            .shadow(radius: 4)
                            .onMapCameraChange { context in
                                // context.region is an MKCoordinateRegion describing
                                // the current visible area of the map
                                viewModel.updateFromRegion(context.region)
                            }

                        // Center pin overlay – stays fixed while map moves
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.primary)
                            .shadow(radius: 4)

                        // Small circle at exact center (ground point)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .shadow(radius: 2)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.bottom, 4)

                    if let coord = viewModel.selectedCoordinate {
                        Text(String(format: "Lat: %.5f, Lng: %.5f",
                                    coord.latitude, coord.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    // MARK: - Action button
                    Button {
                        Task {
                            await viewModel.loadForecastForCurrentSelection()
                            if viewModel.errorMessage == nil {
                                showResults = true
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("See forecast")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                    .disabled(viewModel.isLoading)

                }
                .padding()
            }
            .navigationTitle("Future Spots")
            .onAppear {
                viewModel.ensureDefaultCoordinate()
                region.center = viewModel.selectedCoordinate ?? region.center
            }
            .navigationDestination(isPresented: $showResults) {
                ForecastResultsView(viewModel: viewModel)
            }
        }
    }
}
struct ForecastView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ForecastView()
        }
        .environment(\.colorScheme, .light)
    }
}
