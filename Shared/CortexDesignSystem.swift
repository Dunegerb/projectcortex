import SwiftUI

/// Native iOS typography. `Font.system` resolves to San Francisco / SF Pro on iPhone.
public enum CortexTextStyle: CaseIterable {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subhead
    case footnote
    case caption1
    case caption2

    public var size: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title1: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subhead: 15
        case .footnote: 13
        case .caption1: 12
        case .caption2: 11
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .headline: .semibold
        default: .regular
        }
    }

    /// Slightly tighter than the system default without creating a display-font look.
    public var tracking: CGFloat {
        switch self {
        case .largeTitle: -0.45
        case .title1: -0.35
        case .title2: -0.26
        case .title3: -0.22
        case .headline, .body: -0.18
        case .callout: -0.16
        case .subhead: -0.14
        case .footnote: -0.10
        case .caption1: -0.08
        case .caption2: -0.06
        }
    }
}

private struct CortexTextStyleModifier: ViewModifier {
    let style: CortexTextStyle
    let weight: Font.Weight?
    let tracking: CGFloat?

    func body(content: Content) -> some View {
        content
            .font(.system(size: style.size, weight: weight ?? style.weight, design: .default))
            .tracking(tracking ?? style.tracking)
    }
}

public extension View {
    /// Applies the app's SF Pro scale with restrained negative tracking.
    func cortexTextStyle(
        _ style: CortexTextStyle,
        weight: Font.Weight? = nil,
        tracking: CGFloat? = nil
    ) -> some View {
        modifier(CortexTextStyleModifier(style: style, weight: weight, tracking: tracking))
    }
}

public enum CortexPalette {
    public static let base = Color(red: 0, green: 0, blue: 0)
    public static let secondary = Color(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0)
    public static let tertiary = Color(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 46.0 / 255.0)
    public static let quaternary = Color(red: 58.0 / 255.0, green: 58.0 / 255.0, blue: 60.0 / 255.0)
}
