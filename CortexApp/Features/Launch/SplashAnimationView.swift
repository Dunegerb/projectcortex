import SwiftUI
import WebKit

/// Hosts the approved HTML/CSS liquid-glass intro without translating its
/// geometry or timing into SwiftUI. WKWebView is intentional here: it lets the
/// IPA render the same masks, SVG filters, bezier curve and 739 × 1600 design
/// space as the supplied browser reference.
struct SplashAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didFinish = false

    let onFinished: () -> Void

    var body: some View {
        CortexSplashWebView(
            reduceMotion: reduceMotion,
            onAnimationFinished: finishOnce
        )
        .background(Color.black)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @MainActor
    private func finishOnce() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

private struct CortexSplashWebView: UIViewRepresentable {
    let reduceMotion: Bool
    let onAnimationFinished: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAnimationFinished: onAnimationFinished)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: Coordinator.messageName)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.suppressesIncrementalRendering = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.underPageBackgroundColor = .black
        webView.isUserInteractionEnabled = false

        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        guard let sourceURL = Bundle.main.url(
            forResource: "SplashIntro",
            withExtension: "html"
        ) else {
            assertionFailure("SplashIntro.html não foi incluído no bundle.")
            context.coordinator.finishAfterFallbackDelay()
            return webView
        }

        var components = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false)
        if reduceMotion {
            components?.queryItems = [URLQueryItem(name: "frame", value: "2")]
        }

        let loadURL = components?.url ?? sourceURL
        webView.loadFileURL(
            loadURL,
            allowingReadAccessTo: sourceURL.deletingLastPathComponent()
        )
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.messageName
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let messageName = "cortexSplash"

        private let onAnimationFinished: @MainActor () -> Void
        private var didFinish = false

        init(onAnimationFinished: @escaping @MainActor () -> Void) {
            self.onAnimationFinished = onAnimationFinished
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // This bridge observes the real CSS transition instead of estimating
            // 900 ms + 800 ms in native code. It does not change any visual rule
            // from SplashIntro.html. Two RAFs ensure frame 2 is painted before
            // the overlay is removed.
            let bridge = """
            (() => {
              if (window.__cortexNativeBridgeInstalled) return;
              window.__cortexNativeBridgeInstalled = true;

              const postFinished = () => {
                if (window.__cortexNativeFinished) return;
                window.__cortexNativeFinished = true;
                requestAnimationFrame(() => requestAnimationFrame(() => {
                  window.webkit.messageHandlers.\(Self.messageName).postMessage('finished');
                }));
              };

              const loader = document.getElementById('loader');
              const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
              const fixed = new URLSearchParams(location.search).get('frame');

              if (fixed === '2' || reduced) {
                requestAnimationFrame(() => requestAnimationFrame(postFinished));
                return;
              }

              const target = document.querySelector('.icon-logo');
              if (target) {
                target.addEventListener('transitionend', event => {
                  if (event.propertyName === 'width' && loader?.classList.contains('is-frame-2')) {
                    postFinished();
                  }
                }, { passive: true });
              }

              // Safety only: normal completion is driven by transitionend.
              setTimeout(postFinished, 3500);
            })();
            """

            webView.evaluateJavaScript(bridge) { [weak self] _, error in
                if error != nil {
                    self?.finishAfterFallbackDelay()
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            finishAfterFallbackDelay()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            finishAfterFallbackDelay()
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == Self.messageName else { return }
            finishOnce()
        }

        func finishAfterFallbackDelay() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.finishOnce()
            }
        }

        private func finishOnce() {
            guard !didFinish else { return }
            didFinish = true
            Task { @MainActor [onAnimationFinished] in
                onAnimationFinished()
            }
        }
    }
}
