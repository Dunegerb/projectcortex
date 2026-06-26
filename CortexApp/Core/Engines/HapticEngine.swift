import CoreHaptics
import UIKit

final class HapticEngine {
    static let shared = HapticEngine()

    private var engine: CHHapticEngine?

    private init() {
        prepare()
    }

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func softPulse() {
        play(events: [event(time: 0, intensity: 0.35, sharpness: 0.15)])
    }

    func victory() {
        let events = [
            event(time: 0.00, intensity: 0.50, sharpness: 0.45),
            event(time: 0.16, intensity: 0.62, sharpness: 0.50),
            event(time: 0.32, intensity: 0.78, sharpness: 0.55),
            event(time: 0.82, intensity: 1.00, sharpness: 0.35)
        ]
        play(events: events)
    }

    func ramp(level: Double) {
        let value = Float(min(max(level, 0.1), 1.0))
        play(events: [event(time: 0, intensity: value, sharpness: 0.25 + value * 0.35)])
    }

    func heartbeat(bpm: Double = 60, duration: TimeInterval = 8) {
        let interval = 60.0 / max(bpm, 1)
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        while time < duration {
            events.append(event(time: time, intensity: 0.72, sharpness: 0.25))
            events.append(event(time: time + 0.16, intensity: 0.45, sharpness: 0.16))
            time += interval
        }
        play(events: events)
    }

    func impactFallback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func event(time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private func play(events: [CHHapticEvent]) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            impactFallback()
            return
        }
        do {
            if engine == nil { prepare() }
            try engine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impactFallback()
        }
    }
}
