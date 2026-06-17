import CoreHaptics
import UIKit

/// Subtle haptic accompaniment to the awakening visual: one continuous low hum whose
/// intensity rises with download progress (Core Haptics, live-modulated), discrete
/// taps at 25/50/75% milestones, and a success swell on completion. Foreground-only —
/// the engine is rebuilt when the app returns to the foreground (Core Haptics stops
/// the engine on suspend and does not auto-restart). No-ops on hardware without
/// haptics, the Simulator, or when the user disabled them.
final class OracleHapticConductor {

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var lastMilestone = 0
    private var isRunning = false

    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: "StreamingHapticsEnabled") as? Bool ?? true
    }

    deinit { stop() }

    func start() {
        guard supportsHaptics, enabled, !isRunning else { return }
        isRunning = true
        impact.prepare()
        notification.prepare()
        buildEngine()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleForeground),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    @objc private func handleForeground() {
        guard isRunning else { return }
        buildEngine()
    }

    private func buildEngine() {
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                try? self?.engine?.start()
                self?.startHum()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            self.engine = engine
            startHum()
        } catch {
            AppLogger.ui.error("Haptic engine start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func startHum() {
        guard let engine else { return }
        let hum = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0,
            duration: 60 * 30
        )
        do {
            let pattern = try CHHapticPattern(events: [hum], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            AppLogger.ui.error("Haptic hum failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(progress: Float) {
        guard isRunning, supportsHaptics, enabled else { return }
        let scaled = 0.15 + 0.6 * max(0, min(progress, 1))
        try? player?.sendParameters(
            [CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: scaled, relativeTime: 0)],
            atTime: CHHapticTimeImmediate
        )
        let milestone = Int(progress * 4)
        if milestone > lastMilestone && milestone < 4 {
            lastMilestone = milestone
            impact.impactOccurred(intensity: 0.6)
        }
    }

    func complete() {
        let wasRunning = isRunning
        stop()
        if wasRunning, supportsHaptics, enabled {
            notification.notificationOccurred(.success)
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop(completionHandler: nil)
        engine = nil
        lastMilestone = 0
    }
}
