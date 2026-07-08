import SwiftUI

/// Fully native Cortex startup animation.
///
/// The approved composition was authored in a 739 × 1600 design space and
/// displayed inside a 375 × 812 viewport. Runtime layers are laid out directly
/// in screen coordinates; the complete scene is never scaled or flattened as a
/// single compositing group. This avoids an iOS renderer issue that can rebase
/// transformed vector layers to the upper-left corner during startup.
struct SplashAnimationView: View {
    private enum Timing {
        static let initialHoldNanoseconds: UInt64 = 900_000_000
        static let transitionNanoseconds: UInt64 = 800_000_000
        static let finalHoldNanoseconds: UInt64 = 50_000_000
        static let transition = Animation.timingCurve(1, 0.01, 0, 0.99, duration: 0.8)
    }

    @State private var isFrame2 = false
    @State private var didStart = false
    @State private var didFinish = false

    let onFinished: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let viewport = SplashViewport(containerSize: proxy.size)

            ZStack(alignment: .topLeading) {
                Color.black
                    .frame(width: proxy.size.width, height: proxy.size.height)

                SplashScene(viewport: viewport, isFrame2: isFrame2)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .topLeading
            )
            .clipped()
        }
        .background(Color.black)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            await runAnimationOnce()
        }
    }

    @MainActor
    private func runAnimationOnce() async {
        guard !didStart else { return }
        didStart = true

        try? await Task.sleep(nanoseconds: Timing.initialHoldNanoseconds)
        guard !Task.isCancelled else { return }

        withAnimation(Timing.transition) {
            isFrame2 = true
        }

        try? await Task.sleep(
            nanoseconds: Timing.transitionNanoseconds + Timing.finalHoldNanoseconds
        )
        guard !Task.isCancelled else { return }
        finishOnce()
    }

    @MainActor
    private func finishOnce() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

private struct SplashScene: View {
    let viewport: SplashViewport
    let isFrame2: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            sceneLight(
                start: SplashRect(x: 173, y: 680, width: 33, height: 59.627),
                end: SplashRect(x: 479, y: 696, width: 82, height: 62)
            )

            sceneLight(
                start: SplashRect(x: 173, y: 821.373, width: 33, height: 59.627),
                end: SplashRect(x: 479, y: 843, width: 82, height: 62)
            )

            placedGlassLens

            SplashCrossfadeLogo(
                isFrame2: isFrame2,
                startAsset: "SplashIconLogoStart",
                endAsset: "SplashIconLogoEnd"
            )
            .splashFrame(
                viewport.screenRect(
                    isFrame2
                        ? SplashRect(x: 288, y: 735, width: 164, height: 131)
                        : SplashRect(x: 337, y: 774, width: 66, height: 53)
                )
            )

            SplashCrossfadeLogo(
                isFrame2: isFrame2,
                startAsset: "SplashTextLogoStart",
                endAsset: "SplashTextLogoEnd"
            )
            .splashFrame(
                viewport.screenRect(
                    isFrame2
                        ? SplashRect(x: 355, y: 790, width: 29, height: 19)
                        : SplashRect(x: 304, y: 756, width: 131, height: 88)
                )
            )
        }
        .frame(
            width: viewport.containerSize.width,
            height: viewport.containerSize.height,
            alignment: .topLeading
        )
    }

    private var placedGlassLens: some View {
        let frame = viewport.screenRect(
            SplashRect(x: 149, y: 651, width: 442, height: 298)
        )

        return SplashGlassLens(viewport: viewport, isFrame2: isFrame2)
            .splashFrame(frame)
    }

    private func sceneLight(start: SplashRect, end: SplashRect) -> some View {
        let frame = viewport.screenRect(isFrame2 ? end : start)

        return Rectangle()
            .fill(Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255))
            .blur(radius: 23.4 * viewport.effectScale, opaque: false)
            .splashFrame(frame)
    }
}

private struct SplashGlassLens: View {
    let viewport: SplashViewport
    let isFrame2: Bool

    private var lensSize: CGSize {
        CGSize(
            width: 442 * viewport.scaleX,
            height: 298 * viewport.scaleY
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            refractedLights
                .distortionEffect(
                    ShaderLibrary.cortexLiquidWarp(
                        .float(Float(viewport.scaleX)),
                        .float(Float(viewport.scaleY))
                    ),
                    maxSampleOffset: CGSize(
                        width: 9 * viewport.scaleX,
                        height: 9 * viewport.scaleY
                    )
                )
                .mask(glassMask)
                .brightness(0.035)
                .contrast(1.10)

            Color(red: 241 / 255, green: 241 / 255, blue: 241 / 255)
                .opacity(0.01)
                .frame(width: lensSize.width, height: lensSize.height)
                .mask(glassMask)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.004),
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: lensSize.width, height: lensSize.height)
            .mask(glassMask)

            Image("SplashGlassOverlay")
                .resizable()
                .interpolation(.high)
                .frame(width: lensSize.width, height: lensSize.height)
                .shadow(
                    color: Color.white.opacity(0.018),
                    radius: 1.1 * viewport.effectScale,
                    x: -0.4 * viewport.scaleX,
                    y: -0.4 * viewport.scaleY
                )

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.42),
                    .init(color: Color.white.opacity(0.013), location: 0.68),
                    .init(color: Color.white.opacity(0.045), location: 0.82),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .frame(width: lensSize.width, height: lensSize.height)
            .mask(glassMask)
            .opacity(0.2)
        }
        .frame(width: lensSize.width, height: lensSize.height, alignment: .topLeading)
    }

    private var glassMask: some View {
        Image("SplashGlassMask")
            .resizable()
            .interpolation(.high)
            .frame(width: lensSize.width, height: lensSize.height)
    }

    private var refractedLights: some View {
        ZStack(alignment: .topLeading) {
            refractedLight(
                start: SplashRect(x: 24, y: 29, width: 33, height: 59.627),
                end: SplashRect(x: 330, y: 45, width: 82, height: 62)
            )

            refractedLight(
                start: SplashRect(x: 24, y: 170.373, width: 33, height: 59.627),
                end: SplashRect(x: 330, y: 192, width: 82, height: 62)
            )

            caustic(
                start: SplashRect(x: 48, y: 25, width: 10, height: 70),
                end: SplashRect(x: 397, y: 40, width: 10, height: 72),
                startOpacity: 0.08,
                endOpacity: 0.06
            )

            caustic(
                start: SplashRect(x: 48, y: 166, width: 10, height: 70),
                end: SplashRect(x: 397, y: 187, width: 10, height: 72),
                startOpacity: 0.08,
                endOpacity: 0.06
            )
        }
        .frame(width: lensSize.width, height: lensSize.height, alignment: .topLeading)
    }

    private func refractedLight(start: SplashRect, end: SplashRect) -> some View {
        let frame = viewport.localRect(isFrame2 ? end : start)
        let base = Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)

        return ZStack {
            Rectangle()
                .fill(base)

            Rectangle()
                .fill(Color(red: 138 / 255, green: 216 / 255, blue: 1).opacity(0.02))
                .offset(
                    x: 0.45 * viewport.scaleX,
                    y: -0.25 * viewport.scaleY
                )

            Rectangle()
                .fill(Color(red: 1, green: 159 / 255, blue: 207 / 255).opacity(0.014))
                .offset(
                    x: -0.4 * viewport.scaleX,
                    y: 0.28 * viewport.scaleY
                )
        }
        .blur(radius: 23.4 * viewport.effectScale, opaque: false)
        .splashFrame(frame)
    }

    private func caustic(
        start: SplashRect,
        end: SplashRect,
        startOpacity: Double,
        endOpacity: Double
    ) -> some View {
        let frame = viewport.localRect(isFrame2 ? end : start)

        return Capsule()
            .fill(Color.white.opacity(0.025))
            .blur(radius: 6 * viewport.effectScale, opaque: false)
            .opacity(isFrame2 ? endOpacity : startOpacity)
            .splashFrame(frame)
    }
}

private struct SplashCrossfadeLogo: View {
    let isFrame2: Bool
    let startAsset: String
    let endAsset: String

    var body: some View {
        ZStack {
            Image(startAsset)
                .resizable()
                .interpolation(.high)
                .opacity(isFrame2 ? 0 : 1)

            Image(endAsset)
                .resizable()
                .interpolation(.high)
                .opacity(isFrame2 ? 1 : 0)
        }
    }
}

private struct SplashViewport {
    static let referenceViewport = CGSize(width: 375, height: 812)
    static let designSpace = CGSize(width: 739, height: 1600)

    let containerSize: CGSize
    let viewportScale: CGFloat
    let scaleX: CGFloat
    let scaleY: CGFloat
    let originX: CGFloat
    let originY: CGFloat

    init(containerSize: CGSize) {
        self.containerSize = containerSize

        let safeWidth = max(containerSize.width, 1)
        let safeHeight = max(containerSize.height, 1)
        let fittedScale = min(
            safeWidth / Self.referenceViewport.width,
            safeHeight / Self.referenceViewport.height
        )
        viewportScale = fittedScale
        scaleX = (Self.referenceViewport.width / Self.designSpace.width) * fittedScale
        scaleY = (Self.referenceViewport.height / Self.designSpace.height) * fittedScale
        originX = (containerSize.width - Self.referenceViewport.width * fittedScale) / 2
        originY = (containerSize.height - Self.referenceViewport.height * fittedScale) / 2
    }

    var effectScale: CGFloat {
        (scaleX + scaleY) / 2
    }

    func screenRect(_ rect: SplashRect) -> CGRect {
        CGRect(
            x: originX + rect.x * scaleX,
            y: originY + rect.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }

    func localRect(_ rect: SplashRect) -> CGRect {
        CGRect(
            x: rect.x * scaleX,
            y: rect.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }
}

private struct SplashRect {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

private extension View {
    /// Places a layer by its top-left corner without `position`, group scaling,
    /// or offscreen rebasing. Width, height and offset remain independently
    /// animatable under the approved timing curve.
    func splashFrame(_ rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height, alignment: .topLeading)
            .offset(x: rect.minX, y: rect.minY)
    }
}
