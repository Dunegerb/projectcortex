import SwiftUI

struct SplashAnimationView: View {
    private enum Layout {
        static let canvasWidth: CGFloat = 739
        static let canvasHeight: CGFloat = 1600
        static let glassWidth: CGFloat = 442
        static let glassHeight: CGFloat = 298

        static let textInitialSize = CGSize(width: 131, height: 88)
        static let textFinalSize = CGSize(width: 29, height: 19)
        static let iconInitialSize = CGSize(width: 66, height: 53)
        static let iconFinalSize = CGSize(width: 164, height: 131)

        static let lightInitialWidth: CGFloat = 33
        static let lightInitialHeight: CGFloat = 59.627
        static let lightFinalWidth: CGFloat = 82
        static let lightFinalHeight: CGFloat = 62
        static let lightBlurRadius: CGFloat = 23.4

        // Coordinates are measured from the center of the supplied 739 × 1600 frames.
        static let topLightInitialOffset = CGSize(width: -180, height: -90.1865)
        static let bottomLightInitialOffset = CGSize(width: -180, height: 51.1865)
        static let topLightFinalOffset = CGSize(width: 150.5, height: -73)
        static let bottomLightFinalOffset = CGSize(width: 150.5, height: 74)

        static let initialHoldNanoseconds: UInt64 = 300_000_000
        static let transitionNanoseconds: UInt64 = 800_000_000
        static let finalHoldNanoseconds: UInt64 = 240_000_000
        static let fadeNanoseconds: UInt64 = 220_000_000
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFinalFrame = false
    @State private var screenOpacity = 1.0
    @State private var didStart = false

    let onFinished: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / Layout.canvasWidth,
                proxy.size.height / Layout.canvasHeight
            )
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Color.black

                light(
                    center: center,
                    scale: scale,
                    initialOffset: Layout.topLightInitialOffset,
                    finalOffset: Layout.topLightFinalOffset
                )

                light(
                    center: center,
                    scale: scale,
                    initialOffset: Layout.bottomLightInitialOffset,
                    finalOffset: Layout.bottomLightFinalOffset
                )

                glassLogo(scale: scale)
                    .position(x: center.x, y: center.y)

                Image("SplashIconLogo")
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .antialiased(true)
                    .foregroundStyle(isFinalFrame ? logoWhite : Color.black)
                    .frame(
                        width: (isFinalFrame ? Layout.iconFinalSize.width : Layout.iconInitialSize.width) * scale,
                        height: (isFinalFrame ? Layout.iconFinalSize.height : Layout.iconInitialSize.height) * scale
                    )
                    .position(x: center.x, y: center.y)

                Image("SplashTextLogo")
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .antialiased(true)
                    .foregroundStyle(isFinalFrame ? Color.black : logoWhite)
                    .frame(
                        width: (isFinalFrame ? Layout.textFinalSize.width : Layout.textInitialSize.width) * scale,
                        height: (isFinalFrame ? Layout.textFinalSize.height : Layout.textInitialSize.height) * scale
                    )
                    .position(x: center.x, y: center.y)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .opacity(screenOpacity)
        .accessibilityHidden(true)
        .task {
            await runAnimationOnce()
        }
    }

    private var logoWhite: Color {
        Color(red: 241 / 255, green: 241 / 255, blue: 241 / 255)
    }

    private var lightGray: Color {
        Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)
    }

    private func light(
        center: CGPoint,
        scale: CGFloat,
        initialOffset: CGSize,
        finalOffset: CGSize
    ) -> some View {
        let offset = isFinalFrame ? finalOffset : initialOffset
        let width = isFinalFrame ? Layout.lightFinalWidth : Layout.lightInitialWidth
        let height = isFinalFrame ? Layout.lightFinalHeight : Layout.lightInitialHeight

        return Rectangle()
            .fill(lightGray)
            .frame(width: width * scale, height: height * scale)
            .blur(radius: Layout.lightBlurRadius * scale)
            .position(
                x: center.x + offset.width * scale,
                y: center.y + offset.height * scale
            )
    }

    private func glassLogo(scale: CGFloat) -> some View {
        let width = Layout.glassWidth * scale
        let height = Layout.glassHeight * scale

        return ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    glassMask(width: width, height: height)
                }

            glassMask(width: width, height: height)
                .foregroundStyle(Color.white.opacity(0.012))

            // The supplied glass uses a -45° light at 13%. The low layer
            // opacity keeps that directional sheen subtle over the 1% fill.
            glassMask(width: width, height: height)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.13),
                            Color.clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .opacity(0.27)
                .blendMode(.screen)
        }
        .frame(width: width, height: height)
    }

    private func glassMask(width: CGFloat, height: CGFloat) -> some View {
        Image("SplashGlassLogoMask")
            .resizable()
            .renderingMode(.template)
            .interpolation(.high)
            .antialiased(true)
            .frame(width: width, height: height)
    }

    @MainActor
    private func runAnimationOnce() async {
        guard !didStart else { return }
        didStart = true

        if reduceMotion {
            isFinalFrame = true
            try? await Task.sleep(nanoseconds: 420_000_000)
        } else {
            try? await Task.sleep(nanoseconds: Layout.initialHoldNanoseconds)
            guard !Task.isCancelled else { return }

            withAnimation(
                .timingCurve(
                    1,
                    0.01,
                    0,
                    0.99,
                    duration: Double(Layout.transitionNanoseconds) / 1_000_000_000
                )
            ) {
                isFinalFrame = true
            }

            try? await Task.sleep(
                nanoseconds: Layout.transitionNanoseconds + Layout.finalHoldNanoseconds
            )
        }

        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: Double(Layout.fadeNanoseconds) / 1_000_000_000)) {
            screenOpacity = 0
        }

        try? await Task.sleep(nanoseconds: Layout.fadeNanoseconds)
        guard !Task.isCancelled else { return }
        onFinished()
    }
}
