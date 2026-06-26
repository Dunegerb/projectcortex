import SwiftUI
import UIKit

enum CortexTheme {
    // Apple-style OLED elevation palette.
    static let base = CortexPalette.base
    static let secondary = CortexPalette.secondary
    static let tertiary = CortexPalette.tertiary
    static let quaternary = CortexPalette.quaternary

    // Compatibility aliases used by existing feature views.
    static let navy = base
    static let slate = secondary

    // Functional accents remain intentionally restrained.
    static let moss = Color(red: 0.28, green: 0.43, blue: 0.36)
    static let ice = Color(red: 0.47, green: 0.72, blue: 0.86)
    static let muted = Color(red: 0.56, green: 0.56, blue: 0.58)
    static let danger = Color(red: 0.55, green: 0.18, blue: 0.20)
    static let paper = Color(red: 0.91, green: 0.93, blue: 0.92)

    static let background = LinearGradient(
        colors: [base, base],
        startPoint: .top,
        endPoint: .bottom
    )

    static func configureSystemAppearance() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = UIColor(secondary)
        navigation.shadowColor = UIColor(quaternary)
        navigation.titleTextAttributes = textAttributes(style: .headline, color: .white)
        navigation.largeTitleTextAttributes = textAttributes(style: .largeTitle, color: .white)

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navigation
        navigationBar.scrollEdgeAppearance = navigation
        navigationBar.compactAppearance = navigation
        navigationBar.tintColor = UIColor(ice)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(secondary)
        tab.shadowColor = UIColor(quaternary)

        let normal = textAttributes(style: .caption2, color: UIColor.secondaryLabel)
        let selected = textAttributes(style: .caption2, color: UIColor(ice))
        tab.stackedLayoutAppearance.normal.titleTextAttributes = normal
        tab.stackedLayoutAppearance.selected.titleTextAttributes = selected
        tab.inlineLayoutAppearance.normal.titleTextAttributes = normal
        tab.inlineLayoutAppearance.selected.titleTextAttributes = selected
        tab.compactInlineLayoutAppearance.normal.titleTextAttributes = normal
        tab.compactInlineLayoutAppearance.selected.titleTextAttributes = selected

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.tintColor = UIColor(ice)
        tabBar.unselectedItemTintColor = UIColor.secondaryLabel

        UISearchTextField.appearance().backgroundColor = UIColor(quaternary)
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
                            .stroke(CortexTheme.quaternary.opacity(0.72), lineWidth: 1)
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
