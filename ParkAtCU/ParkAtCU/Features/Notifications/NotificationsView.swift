//
//  NotificationsView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//

import SwiftUI
import MapKit

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.notifications.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                Text("No notifications yet")
                    .font(.headline)

                Text("Arm the watch in the Current tab to get notified when a spot opens up.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            List(appState.notifications) { notification in
                Button {
                    openInMaps(notification: notification)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppTheme.primary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.subheadline.bold())

                            Text(String(format: "Lat: %.5f, Lng: %.5f",
                                        notification.lat, notification.lng))
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(notification.createdAt, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func openInMaps(notification: SpotNotification) {
        let coordinate = CLLocationCoordinate2D(
            latitude: notification.lat,
            longitude: notification.lng
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = notification.spotID

        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let state = AppState()
        state.notifications = [
            SpotNotification(
                id: UUID(),
                spotID: "spot-101",
                lat: 40.8075,
                lng: -73.9626,
                createdAt: Date().addingTimeInterval(-120),
                cameraID: "cam-001"
            ),
            SpotNotification(
                id: UUID(),
                spotID: "spot-202",
                lat: 40.8072,
                lng: -73.9630,
                createdAt: Date().addingTimeInterval(-600),
                cameraID: "cam-002"
            )
        ]

        return NavigationStack {
            NotificationsView()
        }
        .environmentObject(state)
    }
}
