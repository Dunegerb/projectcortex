import SwiftData
import SwiftUI

@main
struct CortexApp: App {
    @UIApplicationDelegateAdaptor(CortexAppDelegate.self) private var appDelegate
    @StateObject private var router = AppRouter()
    @AppStorage(AppAppearanceMode.storageKey) private var appearanceModeRaw = AppAppearanceMode.system.rawValue
    private let modelContainer: ModelContainer

    init() {
        CortexTheme.configureSystemAppearance()

        let schema = Schema([
            UserProfile.self,
            RecoveryLetter.self,
            DailyCheckIn.self,
            EmergencySession.self,
            JournalEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Não foi possível iniciar o banco local: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(router)
                .preferredColorScheme(appearanceMode.colorScheme)
                .onOpenURL { router.handle(url: $0) }
                .task {
                    await ScreenTimeService.shared.restoreAndApplyIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }

    private var appearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }
}
