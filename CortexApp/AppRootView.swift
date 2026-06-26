import SwiftData
import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var router: AppRouter
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            CortexTheme.background.ignoresSafeArea()

            if let profile = profiles.first, profile.onboardingCompleted {
                MainTabView(profile: profile)
                    .fullScreenCover(isPresented: $router.showEmergency) {
                        EmergencyFlowView(profile: profile)
                    }
            } else {
                OnboardingView()
            }
        }
        // Explicitly consume the complete UIWindow proposal. Together with the
        // native launch-screen declaration this prevents legacy/letterboxed
        // presentation on modern iPhones.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cortexTextStyle(.body)
    }
}

struct MainTabView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        TabView {
            DashboardView(profile: profile)
                .tabItem { Label("Início", systemImage: "figure.mind.and.body") }
            JournalView()
                .tabItem { Label("Diário", systemImage: "book.closed") }
            MilestonesView(profile: profile)
                .tabItem { Label("Marcos", systemImage: "mountain.2") }
            ShieldSettingsView(profile: profile)
                .tabItem { Label("Escudo", systemImage: "shield.checkered") }
            SettingsView(profile: profile)
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbarBackground(CortexTheme.secondary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(CortexTheme.ice)
    }
}
