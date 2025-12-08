import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    enum Tab {
        case current
        case predict
        case notifications
        case profile
    }

    @State private var selectedTab: Tab = .current

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // CURRENT TAB
                NavigationStack {
                    CurrentView(
                        viewModel: SpotsViewModel(appState: appState),
                        autoLoad: true
                    )
                    .toolbar(.hidden, for: .navigationBar)   // full-screen map
                }
                .tabItem {
                    Label("Current", systemImage: "car.fill")
                }
                .tag(Tab.current)

                // PREDICT TAB
                NavigationStack {
                    ForecastView()
                        .navigationTitle("Future Spots")
                }
                .tabItem {
                    Label("Predict", systemImage: "clock.fill")
                }
                .tag(Tab.predict)

                // NOTIFICATIONS TAB
                NavigationStack {
                    NotificationsView()
                        .navigationTitle("Notifications")
                }
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(Tab.notifications)

                // PROFILE TAB
                NavigationStack {
                    ProfileView()
                        .navigationTitle("Profile")
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
            }

            // In-app banner overlay
            if let banner = appState.activeNotification {
                NotificationBannerView(
                    notification: banner,
                    onTap: {
                        // clear banner + jump to Notifications tab
                        appState.activeNotification = nil
                        selectedTab = .notifications
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: appState.activeNotification)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
