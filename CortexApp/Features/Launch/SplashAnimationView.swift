import SwiftUI

/// Fully native Cortex startup animation.
///
/// The implementation mirrors the approved 375 × 812 reference in a
/// 739 × 1600 design space. Every moving property uses the same 800 ms
/// cubic timing curve after a 900 ms initial hold. The view contains no
/// movie, HTML, JavaScript, WebKit, network access, or runtime decoding.
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
            let viewportScale = min(proxy.size.width / 375, proxy.size.height / 812)
            let viewportWidth = 375 * viewportScale
            let viewportHeight = 812 * viewportScale
            let viewportX = (proxy.size.width - viewportWidth) / 2
            let viewportY = (proxy.size.height - viewportHeight) / 2

            ZStack(alignment: .topLeading) {
                Color.black

                SplashDesignSpace(isFrame2: isFrame2)
                    .frame(width: 739, height: 1600, alignment: .topLeading)
                    .scaleEffect(
                        x: 0.5074424899 * viewportScale,
                        y: 0.5075 * viewportScale,
                        anchor: .topLeading
                    )
                    .offset(x: viewportX, y: viewportY)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
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

private struct SplashDesignSpace: View {
    let isFrame2: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black
                .frame(width: 739, height: 1600)

            sceneLight(
                start: SplashRect(x: 173, y: 680, width: 33, height: 59.627),
                end: SplashRect(x: 479, y: 696, width: 82, height: 62)
            )

            sceneLight(
                start: SplashRect(x: 173, y: 821.373, width: 33, height: 59.627),
                end: SplashRect(x: 479, y: 843, width: 82, height: 62)
            )

            SplashGlassLens(isFrame2: isFrame2)
                .frame(width: 442, height: 298)
                .position(x: 149 + 221, y: 651 + 149)

            SplashCrossfadeLogo(
                isFrame2: isFrame2,
                startAsset: "SplashIconLogoStart",
                endAsset: "SplashIconLogoEnd",
                start: SplashRect(x: 337, y: 774, width: 66, height: 53),
                end: SplashRect(x: 288, y: 735, width: 164, height: 131)
            )

            SplashCrossfadeLogo(
                isFrame2: isFrame2,
                startAsset: "SplashTextLogoStart",
                endAsset: "SplashTextLogoEnd",
                start: SplashRect(x: 304, y: 756, width: 131, height: 88),
                end: SplashRect(x: 355, y: 790, width: 29, height: 19)
            )
        }
        .frame(width: 739, height: 1600, alignment: .topLeading)
        .compositingGroup()
    }

    private func sceneLight(start: SplashRect, end: SplashRect) -> some View {
        let rect = isFrame2 ? end : start

        return Rectangle()
            .fill(Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255))
            .frame(width: rect.width, height: rect.height)
            .blur(radius: 23.4, opaque: false)
            .position(x: rect.centerX, y: rect.centerY)
    }
}

private struct SplashGlassLens: View {
    let isFrame2: Bool

    var body: some View {
        ZStack {
            refractedLights
                .distortionEffect(
                    ShaderLibrary.cortexLiquidWarp(),
                    maxSampleOffset: CGSize(width: 9, height: 9)
                )
                .mask(glassMask)
                .brightness(0.035)
                .contrast(1.10)

            Color(red: 241 / 255, green: 241 / 255, blue: 241 / 255)
                .opacity(0.01)
                .mask(glassMask)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.004),
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(glassMask)

            Image("SplashGlassOverlay")
                .resizable()
                .interpolation(.high)
                .frame(width: 442, height: 298)
                .shadow(color: Color.white.opacity(0.018), radius: 1.1, x: -0.4, y: -0.4)

            // Directional −45° highlight, matching the reference's subtle
            // distant specular light without using private layer filters.
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
            .mask(glassMask)
            .opacity(0.2)
        }
        .frame(width: 442, height: 298)
    }

    private var glassMask: some View {
        Image("SplashGlassMask")
            .resizable()
            .interpolation(.high)
            .frame(width: 442, height: 298)
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
        .frame(width: 442, height: 298, alignment: .topLeading)
    }

    private func refractedLight(start: SplashRect, end: SplashRect) -> some View {
        let rect = isFrame2 ? end : start
        let base = Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)

        return ZStack {
            Rectangle()
                .fill(base)

            // Small native chromatic offsets reproduce the nearly invisible
            // dispersion in the approved SVG while keeping the material dark.
            Rectangle()
                .fill(Color(red: 138 / 255, green: 216 / 255, blue: 1).opacity(0.02))
                .offset(x: 0.45, y: -0.25)

            Rectangle()
                .fill(Color(red: 1, green: 159 / 255, blue: 207 / 255).opacity(0.014))
                .offset(x: -0.4, y: 0.28)
        }
        .frame(width: rect.width, height: rect.height)
        .blur(radius: 23.4, opaque: false)
        .position(x: rect.centerX, y: rect.centerY)
    }

    private func caustic(
        start: SplashRect,
        end: SplashRect,
        startOpacity: Double,
        endOpacity: Double
    ) -> some View {
        let rect = isFrame2 ? end : start

        return Capsule()
            .fill(Color.white.opacity(0.025))
            .frame(width: rect.width, height: rect.height)
            .blur(radius: 6, opaque: false)
            .opacity(isFrame2 ? endOpacity : startOpacity)
            .position(x: rect.centerX, y: rect.centerY)
    }
}

private struct SplashCrossfadeLogo: View {
    let isFrame2: Bool
    let startAsset: String
    let endAsset: String
    let start: SplashRect
    let end: SplashRect

    var body: some View {
        let rect = isFrame2 ? end : start

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
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.centerX, y: rect.centerY)
    }
}

private struct SplashRect {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var centerX: CGFloat { x + width / 2 }
    var centerY: CGFloat { y + height / 2 }
}
