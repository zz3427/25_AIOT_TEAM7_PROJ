//
//  AppState.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/7/25.
//

import Foundation
import SwiftUI

final class AppState: ObservableObject {
    // All past notifications (most recent first)
    @Published var notifications: [SpotNotification] = []

    // Currently displayed banner (if any)
    @Published var activeNotification: SpotNotification?

    /// Called by SpotsViewModel when a new empty spot appears.
    @MainActor
    func addNotification(for spot: ParkingSpot) {
        let notification = SpotNotification(
            id: UUID(),
            spotID: spot.spotID,
            lat: spot.lat,
            lng: spot.lng,
            createdAt: Date(),
            cameraID: spot.sourceCameraID
        )

        // store at top of list
        notifications.insert(notification, at: 0)

        // show banner for this notification
        showBanner(for: notification)
    }

    @MainActor
    private func showBanner(for notification: SpotNotification) {
        activeNotification = notification

        // auto-hide after ~4 seconds
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            if self.activeNotification?.id == notification.id {
                self.activeNotification = nil
            }
        }
    }
}
