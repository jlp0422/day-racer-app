import SwiftUI

@main
struct DayRacerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeTab()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                LeaderboardTab()
                    .tabItem {
                        Label("Leaderboard", systemImage: "trophy.fill")
                    }

                FriendsTab()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }

                ProfileTab()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
            }
            .tint(GameConstants.Visual.dayRacerRed)
        }
    }
}

// MARK: - Tab Placeholders

private struct HomeTab: View {
    var body: some View {
        NavigationStack {
            ContentView()
                .navigationTitle("DayRacer")
        }
    }
}

private struct LeaderboardTab: View {
    var body: some View {
        NavigationStack {
            Text("Leaderboard")
                .navigationTitle("Leaderboard")
        }
    }
}

private struct FriendsTab: View {
    var body: some View {
        NavigationStack {
            Text("Friends")
                .navigationTitle("Friends")
        }
    }
}

private struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            Text("Profile")
                .navigationTitle("Profile")
        }
    }
}
