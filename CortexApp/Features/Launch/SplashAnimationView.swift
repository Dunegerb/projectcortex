import AVFoundation
import SwiftUI
import UIKit

/// Native startup presentation. The approved browser animation is rendered
/// offline into a short, silent H.264 asset and played by AVFoundation. No
/// HTML, JavaScript, network access, or WebKit process is used at runtime.
struct SplashAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didFinish = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.black

            Image(reduceMotion ? "SplashFinalFrame" : "SplashFirstFrame")
                .resizable()
                .interpolation(.high)
                .aspectRatio(375.0 / 812.0, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !reduceMotion {
                CortexSplashVideoPlayer(onFinished: finishOnce)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                finishOnce()
            }
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

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
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
        private var player: AVPlayer?
        private var itemStatusObservation: NSKeyValueObservation?
        private var displayObservation: NSKeyValueObservation?
        private var endObserver: NSObjectProtocol?
        private var failureObserver: NSObjectProtocol?
        private var timeoutWorkItem: DispatchWorkItem?
        private var didFinish = false

        init(onFinished: @escaping @MainActor () -> Void) {
            self.onFinished = onFinished
        }

        func start(in view: SplashPlayerView) {
            guard let videoURL = Bundle.main.url(
                forResource: "CortexSplashIntro",
                withExtension: "mp4"
            ) else {
                assertionFailure("CortexSplashIntro.mp4 não foi incluído no bundle.")
                finishAfterFallbackDelay()
                return
            }

            let asset = AVURLAsset(
                url: videoURL,
                options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            )
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 0

            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .pause
            player.automaticallyWaitsToMinimizeStalling = false
            player.isMuted = true
            self.player = player

            view.playerLayer.player = player
            view.playerLayer.videoGravity = .resizeAspect
            view.playerLayer.backgroundColor = UIColor.clear.cgColor
            view.playerLayer.isHidden = true

            displayObservation = view.playerLayer.observe(
                \.isReadyForDisplay,
                options: [.initial, .new]
            ) { [weak view] layer, _ in
                guard layer.isReadyForDisplay else { return }
                DispatchQueue.main.async {
                    view?.playerLayer.isHidden = false
                }
            }

            itemStatusObservation = item.observe(
                \.status,
                options: [.initial, .new]
            ) { [weak self] item, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch item.status {
                    case .readyToPlay:
                        self.player?.seek(
                            to: .zero,
                            toleranceBefore: .zero,
                            toleranceAfter: .zero
                        ) { [weak self] completed in
                            guard completed else { return }
                            DispatchQueue.main.async {
                                self?.player?.playImmediately(atRate: 1)
                            }
                        }
                    case .failed:
                        self.finishAfterFallbackDelay()
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
                // The movie contains the two final display frames from the
                // approved reference before this notification is emitted.
                self?.finishOnce()
            }

            failureObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.finishAfterFallbackDelay()
            }

            let timeout = DispatchWorkItem { [weak self] in
                self?.finishOnce()
            }
            timeoutWorkItem = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeout)
        }

        func stop() {
            timeoutWorkItem?.cancel()
            timeoutWorkItem = nil
            player?.pause()
            player = nil
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

        private func finishAfterFallbackDelay() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.finishOnce()
            }
        }

        private func finishOnce() {
            guard !didFinish else { return }
            didFinish = true
            stop()
            Task { @MainActor [onFinished] in
                onFinished()
            }
        }

        deinit {
            stop()
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
