import SwiftUI
import UIKit

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "cortex.appearance.mode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Automático"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum CortexTheme {
    // App surfaces. Light values follow the supplied Home light-mode SVG exactly.
    static let base = adaptive(light: 0xF1F1F1, dark: 0x000000)
    static let secondary = adaptive(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let tertiary = adaptive(light: 0xF5F5F5, dark: 0x2C2C2E)
    static let quaternary = adaptive(light: 0xE9E9E9, dark: 0x3A3A3C)

    static let primaryText = adaptive(light: 0x191817, dark: 0xFFFFFF)
    static let secondaryText = adaptive(light: 0x555555, dark: 0x919191)
    static let hairline = adaptive(light: 0xE9E9E9, dark: 0x3A3A3C)

    // Compatibility aliases used by existing feature views.
    static let navy = base
    static let slate = secondary

    // Functional accents remain intentionally restrained.
    static let moss = Color(red: 0.28, green: 0.43, blue: 0.36)
    static let ice = adaptive(light: 0x555555, dark: 0x78B8DB)
    static let muted = adaptive(light: 0x555555, dark: 0x8F8F94)
    static let danger = adaptive(light: 0xB4232B, dark: 0x8C2E33)
    static let paper = Color(red: 0.91, green: 0.93, blue: 0.92)

    static let background = LinearGradient(
        colors: [base, base],
        startPoint: .top,
        endPoint: .bottom
    )

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: adaptiveUIColor(light: light, dark: dark))
    }

    static func adaptiveUIColor(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }

    static func configureSystemAppearance() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = adaptiveUIColor(light: 0xFFFFFF, dark: 0x1C1C1E)
        navigation.shadowColor = adaptiveUIColor(light: 0xE9E9E9, dark: 0x3A3A3C)
        navigation.titleTextAttributes = textAttributes(
            style: .headline,
            color: adaptiveUIColor(light: 0x191817, dark: 0xFFFFFF)
        )
        navigation.largeTitleTextAttributes = textAttributes(
            style: .largeTitle,
            color: adaptiveUIColor(light: 0x191817, dark: 0xFFFFFF)
        )

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navigation
        navigationBar.scrollEdgeAppearance = navigation
        navigationBar.compactAppearance = navigation
        navigationBar.tintColor = adaptiveUIColor(light: 0x555555, dark: 0x78B8DB)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = adaptiveUIColor(light: 0xFFFFFF, dark: 0x1C1C1E)
        tab.shadowColor = adaptiveUIColor(light: 0xE9E9E9, dark: 0x3A3A3C)

        let normal = textAttributes(
            style: .caption2,
            color: adaptiveUIColor(light: 0x555555, dark: 0x919191)
        )
        let selected = textAttributes(
            style: .caption2,
            color: adaptiveUIColor(light: 0x191817, dark: 0x78B8DB)
        )
        tab.stackedLayoutAppearance.normal.titleTextAttributes = normal
        tab.stackedLayoutAppearance.selected.titleTextAttributes = selected
        tab.inlineLayoutAppearance.normal.titleTextAttributes = normal
        tab.inlineLayoutAppearance.selected.titleTextAttributes = selected
        tab.compactInlineLayoutAppearance.normal.titleTextAttributes = normal
        tab.compactInlineLayoutAppearance.selected.titleTextAttributes = selected

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.tintColor = adaptiveUIColor(light: 0x191817, dark: 0x78B8DB)
        tabBar.unselectedItemTintColor = adaptiveUIColor(light: 0x555555, dark: 0x919191)

        UISearchTextField.appearance().backgroundColor = adaptiveUIColor(light: 0xF5F5F5, dark: 0x3A3A3C)
    }

    private static func textAttributes(style: CortexTextStyle, color: UIColor) -> [NSAttributedString.Key: Any] {
        let weight: UIFont.Weight
        switch style {
        case .headline: weight = .semibold
        default: weight = .regular
        }
        return [
            .font: UIFont.systemFont(ofSize: style.size, weight: weight),
            .foregroundColor: color,
            .kern: style.tracking
        ]
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

private struct CortexNativeKeyboardModifier: ViewModifier {
    let capitalization: TextInputAutocapitalization
    let autocorrectionEnabled: Bool
    let submitLabel: SubmitLabel

    func body(content: Content) -> some View {
        content
            .keyboardType(.default)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled(!autocorrectionEnabled)
            .submitLabel(submitLabel)
    }
}

private struct CortexNativeNumberPadModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
    }
}

struct CortexCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(CortexTheme.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(CortexTheme.hairline.opacity(0.72), lineWidth: 1)
                    )
            )
    }
}

extension View {
    /// Uses the standard Apple text keyboard without a custom input view.
    func cortexNativeKeyboard(
        capitalization: TextInputAutocapitalization = .sentences,
        autocorrectionEnabled: Bool = true,
        submitLabel: SubmitLabel = .done
    ) -> some View {
        modifier(CortexNativeKeyboardModifier(
            capitalization: capitalization,
            autocorrectionEnabled: autocorrectionEnabled,
            submitLabel: submitLabel
        ))
    }

    /// Uses Apple's standard numeric keypad.
    func cortexNativeNumberPad() -> some View {
        modifier(CortexNativeNumberPadModifier())
    }

    func cortexCard(padding: CGFloat = 18) -> some View {
        modifier(CortexCard(padding: padding))
    }

    func cortexFadeIn() -> some View {
        modifier(CortexFadeIn())
    }
}

private struct CortexFadeIn: ViewModifier {
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: 0.9), value: visible)
            .onAppear { visible = true }
    }
}
