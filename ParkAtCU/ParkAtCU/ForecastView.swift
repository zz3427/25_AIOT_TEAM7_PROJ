//
//  ForecastView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/4/25.
//

import SwiftUI

struct ForecastView: View {
    @StateObject private var viewModel = ForecastViewModel()

    var body: some View {
        NavigationView {
            VStack {
                // Time picker
                DatePicker(
                    "Forecast for",
                    selection: $viewModel.selectedTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding()

                Button {
                    viewModel.loadForecast()
                } label: {
                    Label("Update Forecast", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)

                Group {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading forecast…")
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Error")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if viewModel.spots.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("No forecast data")
                                .font(.headline)
                            Text("Ask your backend teammate if the /api/spots/forecast endpoint is live.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        List(viewModel.spots) { spot in
                            SpotRow(spot: spot)   // reuse your existing row view
                        }
                    }
                }
            }
            .navigationTitle("Future Spots")
        }
        .onAppear {
            viewModel.loadForecast()
        }
    }
}

struct ForecastView_Previews: PreviewProvider {
    static var previews: some View {
        ForecastView()
    }
}
