import Foundation
import SwiftUI
import WebKit

/// Displays the supplied Kundalini SVG inside a local WKWebView.
/// A compiled vector fallback remains visible until WebKit confirms that the page
/// and its JavaScript controller are ready, preventing an empty hero on device.
struct ChakraExperienceView: View {
    let day: Int
    var animated = true
    var artworkScale: CGFloat = 0.80
    var artworkOffset: CGSize = .zero

    @State private var webContentIsReady = false

    var body: some View {
        ZStack {
            Image("KundaliniPerson")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .opacity(webContentIsReady ? 0 : 0.74)
                .animation(.easeOut(duration: 0.25), value: webContentIsReady)
                .accessibilityHidden(true)

            ChakraWebCanvas(
                day: max(day, 1),
                animated: animated,
                onReady: {
                    withAnimation(.easeOut(duration: 0.25)) {
                        webContentIsReady = true
                    }
                }
            )
            .opacity(webContentIsReady ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: webContentIsReady)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(artworkScale, anchor: .center)
        .offset(artworkOffset)
    }
}

private struct ChakraWebCanvas: UIViewRepresentable {
    let day: Int
    let animated: Bool
    let onReady: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.suppressesIncrementalRendering = false
        configuration.userContentController.add(context.coordinator, name: "cortexReady")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.underPageBackgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false
        webView.accessibilityElementsHidden = true

        context.coordinator.webView = webView
        context.coordinator.pendingDay = max(day, 1)
        context.coordinator.pendingAnimated = animated

        guard let html = Self.loadBundledHTML() else {
            assertionFailure("ChakraExperience.html não foi incluído no bundle.")
            return webView
        }

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(day: max(day, 1), animated: animated)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "cortexReady")
        uiView.navigationDelegate = nil
    }

    private static func loadBundledHTML() -> String? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "ChakraExperience", withExtension: "html"),
            Bundle.main.url(
                forResource: "ChakraExperience",
                withExtension: "html",
                subdirectory: "Resources"
            )
        ]

        for case let url? in candidates {
            if let html = try? String(contentsOf: url, encoding: .utf8), !html.isEmpty {
                return html
            }
        }

        guard let enumerator = FileManager.default.enumerator(
            at: Bundle.main.bundleURL,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            guard url.lastPathComponent == "ChakraExperience.html" else { continue }
            if let html = try? String(contentsOf: url, encoding: .utf8), !html.isEmpty {
                return html
            }
        }

        return nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var pendingDay = 1
        var pendingAnimated = true

        private let onReady: () -> Void
        private var pageIsReady = false
        private var readyWasReported = false
        private var lastDay = -1

        init(onReady: @escaping () -> Void) {
            self.onReady = onReady
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            verifyReadiness(in: webView)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "cortexReady" else { return }
            markReady()
        }

        func update(day: Int, animated: Bool) {
            pendingDay = max(day, 1)
            pendingAnimated = animated
            apply(force: false)
        }

        private func verifyReadiness(in webView: WKWebView) {
            webView.evaluateJavaScript(
                "document.documentElement.dataset.ready === 'true' && typeof window.setCortexDay === 'function'"
            ) { [weak self] result, _ in
                guard let self, (result as? Bool) == true else { return }
                self.markReady()
            }
        }

        private func markReady() {
            pageIsReady = true
            apply(force: true)

            guard !readyWasReported else { return }
            readyWasReported = true
            DispatchQueue.main.async { [onReady] in
                onReady()
            }
        }

        private func apply(force: Bool) {
            guard pageIsReady, let webView else { return }
            guard force || lastDay != pendingDay else { return }

            let animationFlag = pendingAnimated && lastDay >= 0 ? "true" : "false"
            let script = "window.setCortexDay(\(pendingDay), \(animationFlag));"

            webView.evaluateJavaScript(script) { _, error in
                #if DEBUG
                if let error {
                    print("Falha ao sincronizar a figura Kundalini: \(error.localizedDescription)")
                }
                #endif
            }

            lastDay = pendingDay
        }
    }
}
