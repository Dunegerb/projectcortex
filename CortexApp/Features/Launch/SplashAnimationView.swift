import AVFoundation
import SwiftUI
import UIKit

/// Native startup presentation. The approved browser animation is rendered
/// offline into a short, silent H.264 asset and played by AVFoundation. No
/// HTML, JavaScript, network access, or WebKit process is used at runtime.
///
/// The splash is intentionally not shortened when the app finishes loading
/// quickly: the Home screen is released only after the movie reaches its real
/// end. Accessibility Reduce Motion does not bypass this branded intro.
struct SplashAnimationView: View {
    @State private var didFinish = false
    @State private var isUsingFallback = false
    @State private var fallbackShowsFinalFrame = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.black

            Image("SplashFirstFrame")
                .resizable()
                .interpolation(.high)
                .aspectRatio(375.0 / 812.0, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isUsingFallback {
                Image("SplashFinalFrame")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(375.0 / 812.0, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(fallbackShowsFinalFrame ? 1 : 0)
            } else {
                CortexSplashVideoPlayer(
                    onFinished: finishOnce,
                    onPlaybackFailure: beginFallback
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A defensive native fallback used only if iOS cannot decode the bundled
    /// movie. It preserves the same 900 ms hold + 800 ms transition duration,
    /// so a resource failure can never collapse the splash to a few ms.
    @MainActor
    private func beginFallback() {
        guard !didFinish, !isUsingFallback else { return }
        isUsingFallback = true
        fallbackShowsFinalFrame = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard !didFinish else { return }
            withAnimation(.timingCurve(1, 0.01, 0, 0.99, duration: 0.8)) {
                fallbackShowsFinalFrame = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            finishOnce()
        }
    }

    @MainActor
    private func finishOnce() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

private struct CortexSplashVideoPlayer: UIViewRepresentable {
    let onFinished: @MainActor () -> Void
    let onPlaybackFailure: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onFinished: onFinished,
            onPlaybackFailure: onPlaybackFailure
        )
    }

    func makeUIView(context: Context) -> SplashPlayerView {
        let view = SplashPlayerView()
        context.coordinator.start(in: view)
        return view
    }

    func updateUIView(_ uiView: SplashPlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: SplashPlayerView, coordinator: Coordinator) {
        coordinator.stop()
        uiView.playerLayer.player = nil
    }

    final class Coordinator: NSObject {
        private let onFinished: @MainActor () -> Void
        private let onPlaybackFailure: @MainActor () -> Void

        private var player: AVPlayer?
        private var playerItem: AVPlayerItem?
        private var itemStatusObservation: NSKeyValueObservation?
        private var displayObservation: NSKeyValueObservation?
        private var endObserver: NSObjectProtocol?
        private var failureObserver: NSObjectProtocol?
        private var preparationWatchdog: DispatchWorkItem?
        private var playbackWatchdog: DispatchWorkItem?

        private var didStartPlayback = false
        private var didPresentVideoFrame = false
        private var didReachMovieEnd = false
        private var isResolved = false

        init(
            onFinished: @escaping @MainActor () -> Void,
            onPlaybackFailure: @escaping @MainActor () -> Void
        ) {
            self.onFinished = onFinished
            self.onPlaybackFailure = onPlaybackFailure
        }

        func start(in view: SplashPlayerView) {
            guard let videoURL = Bundle.main.url(
                forResource: "CortexSplashIntro",
                withExtension: "mp4"
            ) else {
                assertionFailure("CortexSplashIntro.mp4 não foi incluído no bundle.")
                resolveAsFailure()
                return
            }

            let asset = AVURLAsset(
                url: videoURL,
                options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            )
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 0
            playerItem = item

            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .pause
            player.automaticallyWaitsToMinimizeStalling = true
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            self.player = player

            view.playerLayer.player = player
            view.playerLayer.videoGravity = .resizeAspect
            view.playerLayer.backgroundColor = UIColor.clear.cgColor
            view.playerLayer.isHidden = true

            displayObservation = view.playerLayer.observe(
                \.isReadyForDisplay,
                options: [.initial, .new]
            ) { [weak self, weak view] layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    guard let self, !self.isResolved else { return }
                    self.didPresentVideoFrame = true
                    view?.playerLayer.isHidden = false
                    self.finishOnlyAfterRealMovieEnd()
                }
            }

            itemStatusObservation = item.observe(
                \.status,
                options: [.initial, .new]
            ) { [weak self] item, _ in
                DispatchQueue.main.async {
                    guard let self, !self.isResolved else { return }
                    switch item.status {
                    case .readyToPlay:
                        self.preparationWatchdog?.cancel()
                        self.preparationWatchdog = nil
                        self.seekToBeginningAndPlay()
                    case .failed:
                        self.resolveAsFailure()
                    default:
                        break
                    }
                }
            }

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.handleMovieEnd()
            }

            failureObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.resolveAsFailure()
            }

            let watchdog = DispatchWorkItem { [weak self] in
                self?.resolveAsFailure()
            }
            preparationWatchdog = watchdog
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: watchdog)
        }

        func stop() {
            guard !isResolved else {
                cleanup()
                return
            }
            isResolved = true
            cleanup()
        }

        private func seekToBeginningAndPlay() {
            guard !didStartPlayback, let player else { return }
            didStartPlayback = true

            player.seek(
                to: .zero,
                toleranceBefore: .zero,
                toleranceAfter: .zero
            ) { [weak self] completed in
                DispatchQueue.main.async {
                    guard let self, !self.isResolved else { return }
                    guard completed else {
                        self.resolveAsFailure()
                        return
                    }

                    player.playImmediately(atRate: 1)

                    // This is a stall watchdog, never a normal completion path.
                    // The splash is completed only by AVPlayerItemDidPlayToEndTime.
                    let watchdog = DispatchWorkItem { [weak self] in
                        self?.resolveAsFailure()
                    }
                    self.playbackWatchdog = watchdog
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: watchdog)
                }
            }
        }

        private func handleMovieEnd() {
            guard !isResolved, let item = playerItem else { return }

            let currentSeconds = item.currentTime().seconds
            let durationSeconds = item.duration.seconds
            let hasValidTimes = currentSeconds.isFinite && durationSeconds.isFinite && durationSeconds > 0

            // Never trust an early notification. If the item did not actually
            // reach its final timestamp, restart once from frame zero instead
            // of exposing the Home screen prematurely.
            if hasValidTimes, currentSeconds + 0.025 < durationSeconds {
                didStartPlayback = false
                seekToBeginningAndPlay()
                return
            }

            didReachMovieEnd = true
            finishOnlyAfterRealMovieEnd()
        }

        private func finishOnlyAfterRealMovieEnd() {
            guard didReachMovieEnd, didPresentVideoFrame else { return }
            resolveAsSuccess()
        }

        private func resolveAsSuccess() {
            guard !isResolved else { return }
            isResolved = true
            cleanup()
            Task { @MainActor [onFinished] in
                onFinished()
            }
        }

        private func resolveAsFailure() {
            guard !isResolved else { return }
            isResolved = true
            cleanup()
            Task { @MainActor [onPlaybackFailure] in
                onPlaybackFailure()
            }
        }

        private func cleanup() {
            preparationWatchdog?.cancel()
            preparationWatchdog = nil
            playbackWatchdog?.cancel()
            playbackWatchdog = nil

            player?.pause()
            player = nil
            playerItem = nil
            itemStatusObservation = nil
            displayObservation = nil

            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            if let failureObserver {
                NotificationCenter.default.removeObserver(failureObserver)
                self.failureObserver = nil
            }
        }

        deinit {
            cleanup()
        }
    }
}

private final class SplashPlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }
}
