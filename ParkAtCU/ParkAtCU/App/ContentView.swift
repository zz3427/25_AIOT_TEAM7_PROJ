

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack{
                // 1) Custom bottom background BEHIND the tab icons
                Rectangle()
                    .fill(.ultraThinMaterial)   // translucent / blurry
                    .frame(height: 90)          // tweak if needed
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)    // taps go through to the icons
            }

            // 2) Your real TabView with 4 tabs
            TabView {
                // CURRENT TAB
                NavigationStack {
                    CurrentView(
                        viewModel: SpotsViewModel(),
                        autoLoad: true
                    )
                    // hide nav bar so you don't get a blue top strip
                    .toolbar(.hidden, for: .navigationBar)
                }
                .tabItem {
                    Label("Current", systemImage: "car.fill")
                }

                // PREDICT TAB
                NavigationStack {
                    ForecastView()
                        .navigationTitle("Future Spots")
                }
                .tabItem {
                    Label("Predict", systemImage: "clock.fill")
                }

                // NOTIFICATIONS TAB
                NavigationStack {
                    Text("Notifications coming soon")
                        .navigationTitle("Notifications")
                }
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }

                // PROFILE TAB
                NavigationStack {
                    Text("Profile coming soon")
                        .navigationTitle("Profile")
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
        }
    }
}


//struct ContentView: View {
//    var body: some View {
//        ZStack {
//
//            // 1) Your real TabView with 4 tabs
//            TabView {
//                NavigationStack {
//                    CurrentView(
//                        viewModel: SpotsViewModel(),
//                        autoLoad: true
//                    )
////                    .navigationTitle("Current Empty Spots")
//                }
//                .tabItem {
//                    Label("Current", systemImage: "car.fill")
//                }
//
//                NavigationStack {
//                    ForecastView()
//                        .navigationTitle("Future Spots")
//                }
//                .tabItem {
//                    Label("Predict", systemImage: "clock.fill")
//                }
//
//                NavigationStack {
//                    Text("Notifications coming soon")
//                        .navigationTitle("Notifications")
//                }
//                .tabItem {
//                    Label("Notifications", systemImage: "bell.fill")
//                }
//
//                NavigationStack {
//                    Text("Profile coming soon")
//                        .navigationTitle("Profile")
//                }
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle")
//                }
//            }
//            VStack {
//                Spacer()
//                Rectangle()
//                    .fill(.ultraThinMaterial)   // 🔹 nice translucent blur
//                    .frame(height: 90)          // ~tab bar height; tweak if needed
//                    .ignoresSafeArea(edges: .bottom)
//                    .allowsHitTesting(false)    // ✅ taps go through to the icons
//            }.ignoresSafeArea()
//        }
//    }
//}

#Preview {
    ContentView()
}

//struct ContentView: View {
//    var body: some View {
//        TabView {
//            // 1. Current tab
//            CurrentView(
//                viewModel: SpotsViewModel(),
//                autoLoad: true
//            )
//            .tabItem {
//                Label("Current", systemImage: "car.fill")
//            }
//
//            // 2. Forecast tab
//            ForecastView()
//                .tabItem {
//                    Label("Predict", systemImage: "clock.fill")
//                }
//
//            // 3. Notifications tab
//            NotificationsView()
//                .tabItem {
//                    Label("Alerts", systemImage: "bell.fill")
//                }
//
//            // 4. Profile tab
//            ProfileView()
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle")
//                }
//        }
//    }
//}

#Preview {
    ContentView()
}
