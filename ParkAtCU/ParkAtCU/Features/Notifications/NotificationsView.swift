//
//  NotificationsView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//

import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 40))
                Text("Notifications")
                    .font(.title2)
                    .bold()
                Text("Here you can show alerts when a nearby spot becomes empty, or recent parking events.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .padding()
            .navigationTitle("Notifications")
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
