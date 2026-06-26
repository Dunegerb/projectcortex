import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    @Published var showEmergency = false

    func handle(url: URL) {
        guard url.scheme == "cortex" else { return }
        if url.host == "emergency" {
            showEmergency = true
        }
    }
}
