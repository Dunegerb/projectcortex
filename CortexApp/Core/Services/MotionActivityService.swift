import Combine
import CoreMotion
import Foundation

@MainActor
final class MotionActivityService: ObservableObject {
    @Published private(set) var movementCount = 0
    @Published private(set) var isAvailable = false

    private let manager = CMMotionManager()
    private var lastPeak = Date.distantPast

    func start() {
        movementCount = 0
        isAvailable = manager.isAccelerometerAvailable
        guard manager.isAccelerometerAvailable else { return }
        manager.accelerometerUpdateInterval = 0.10
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let acceleration = data?.acceleration else { return }
            let magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            let now = Date()
            if magnitude > 1.45, now.timeIntervalSince(self.lastPeak) > 0.40 {
                self.lastPeak = now
                self.movementCount += 1
                HapticEngine.shared.softPulse()
            }
        }
    }

    func stop() {
        manager.stopAccelerometerUpdates()
    }
}
