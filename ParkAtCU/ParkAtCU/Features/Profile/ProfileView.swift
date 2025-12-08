//
//  ProfileView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//
import SwiftUI

struct ProfileView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - User Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .foregroundColor(AppTheme.primary.opacity(0.8))

                        Text("Gerald Zhao")
                            .font(.title2.bold())

                        Text("gerald.zhao@columbia.edu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    Divider().padding(.horizontal)

                    // MARK: - Account Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Settings")
                            .font(.headline)

                        profileRow(icon: "bell.fill", title: "Notifications")
                        profileRow(icon: "location.fill", title: "Location Permissions")
                        profileRow(icon: "lock.fill", title: "Privacy Options")
                        profileRow(icon: "car.fill", title: "My Parking Preferences")
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // MARK: - About App
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)

                        profileRow(icon: "info.circle.fill", title: "App Version 1.0")
                        profileRow(icon: "shield.checkerboard", title: "Terms & Policies")
                        profileRow(icon: "person.3.fill", title: "Team 7 — AIoT Project")
                    }
                    .padding(.horizontal)


                    // MARK: - "Logout" Button (demo only)
                    Button {
                        // no real logout logic — placeholder for now
                    } label: {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)

                } // VStack
            } // ScrollView
            .navigationTitle("Profile")
        }
    }

    // MARK: - Reusable Row Component
    @ViewBuilder
    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.primary)

            Text(title)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
