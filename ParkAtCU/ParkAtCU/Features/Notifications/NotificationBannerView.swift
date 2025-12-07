//
//  NotificationBannerView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/7/25.
//

import SwiftUI

struct NotificationBannerView: View {
    let notification: SpotNotification
    let onTap: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)

                    Text(notification.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 6)
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct NotificationBannerView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationBannerView(
            notification: SpotNotification(
                id: UUID(),
                spotID: "spot-101",
                lat: 40.8075,
                lng: -73.9626,
                createdAt: Date(),
                cameraID: "cam-001"
            ),
            onTap: {}
        )
        .background(Color.black.opacity(0.1))
    }
}
