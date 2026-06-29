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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cortexTextStyle(.body)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter
    @Bindable var profile: UserProfile
    @State private var selection: MainSection = .home

    var body: some View {
        GeometryReader { proxy in
            let scale = min(max(proxy.size.width / 375, 0.88), 1.12)
            let bottomInset = proxy.safeAreaInsets.bottom > 0
                ? proxy.safeAreaInsets.bottom
                : (proxy.size.height >= 760 * scale ? 34 * scale : 8 * scale)

            ZStack(alignment: .bottom) {
                selectedContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if selection != .home {
                            Color.clear.frame(height: 76 * scale)
                        }
                    }

                CortexBottomNavigation(
                    selection: $selection,
                    onEmergency: {
                        HapticEngine.shared.impactFallback(.heavy)
                        router.showEmergency = true
                    },
                    scale: scale
                )
                .padding(.horizontal, 24 * scale)
                .padding(.bottom, bottomInset)
            }
            .background(Color.black.ignoresSafeArea())
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selection {
        case .home:
            DashboardView(profile: profile)
        case .journal:
            JournalView()
        case .milestones:
            MilestonesView(profile: profile)
        case .settings:
            SettingsView(profile: profile)
        }
    }
}

private enum MainSection: String, CaseIterable, Identifiable {
    case home
    case journal
    case milestones
    case settings

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .home: return "NavHome"
        case .journal: return "NavJournal"
        case .milestones: return "NavMilestones"
        case .settings: return "NavSettings"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .home: return "Início"
        case .journal: return "Diário"
        case .milestones: return "Marcos"
        case .settings: return "Ajustes"
        }
    }
}

private struct CortexBottomNavigation: View {
    @Binding var selection: MainSection
    let onEmergency: () -> Void
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 1.5 * scale) {
            tabButton(.home)
            tabButton(.journal)
            emergencyButton
            tabButton(.milestones)
            tabButton(.settings)
        }
        .padding(.horizontal, 4 * scale)
        .frame(maxWidth: 326 * scale)
        .frame(height: 69 * scale)
        .background(
            RoundedRectangle(cornerRadius: 34.5 * scale, style: .continuous)
                .fill(Color(red: 27 / 255, green: 27 / 255, blue: 27 / 255).opacity(0.66))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34.5 * scale, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34.5 * scale, style: .continuous)
                .stroke(Color.white.opacity(0.025), lineWidth: 0.7)
        )
    }

    private func tabButton(_ section: MainSection) -> some View {
        Button {
            guard selection != section else { return }
            HapticEngine.shared.softPulse()
            withAnimation(.easeOut(duration: 0.18)) {
                selection = section
            }
        } label: {
            ZStack {
                Circle()
                    .fill(selection == section ? NavigationColors.selected : NavigationColors.inactive)

                Image(section.assetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(selection == section ? Color.white : NavigationColors.icon)
                    .frame(width: 23 * scale, height: 23 * scale)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 61 * scale)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.accessibilityLabel)
        .accessibilityAddTraits(selection == section ? .isSelected : [])
    }

    private var emergencyButton: some View {
        Button(action: onEmergency) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 241 / 255, green: 133 / 255, blue: 133 / 255),
                                Color(red: 168 / 255, green: 19 / 255, blue: 18 / 255),
                                Color(red: 67 / 255, green: 20 / 255, blue: 20 / 255)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 75 * scale
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.20), lineWidth: 0.7)
                    )

                Image("NavEmergency")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 23 * scale, height: 23 * scale)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 61 * scale)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Estou com fissura")
    }
}

private enum NavigationColors {
    static let selected = Color(red: 54 / 255, green: 54 / 255, blue: 54 / 255)
    static let inactive = Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255)
    static let icon = Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255)
}
