//
//  Untitled.swift
//  ParkAtCU
//
//  Created by Gerald Zhao on 12/5/25.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Columbia blue background
            Color(#colorLiteral(red: 0.6157, green: 0.8235, blue: 0.9451, alpha: 1))
                .ignoresSafeArea()

            // NYC grid overlay
            GridOverlay()
                .blendMode(.overlay)
                .opacity(0.25)

            VStack(spacing: 16) {
                Image("AppIcon")    // your generated icon here
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(#colorLiteral(red: 0, green: 0.36, blue: 0.73, alpha: 1)), radius: 10)

                Text("ParkAtCU")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("An AI-powered effort to optimize Columbia parking.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// Grid overlay that looks like an NYC city grid
struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 28

                // vertical lines
                stride(from: 0, through: geo.size.width, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }

                // horizontal lines
                stride(from: 0, through: geo.size.height, by: spacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
        }
        .ignoresSafeArea()
    }
}
