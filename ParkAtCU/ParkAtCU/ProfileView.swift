//
//  ProfileView.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                Text("Profile")
                    .font(.title2)
                    .bold()
                Text("Show user info, settings, radius preferences, etc. here later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
