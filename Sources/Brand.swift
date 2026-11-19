import SwiftUI
import AppKit

// MARK: - Theme layer
// Colours come from ToaColor.swift.
// Type: Cairo for Arabic.

enum TOAFont {
    enum Weight: String {
        case regular = "Cairo-Regular"
        case medium = "Cairo-Medium"
        case semibold = "Cairo-SemiBold"
        case bold = "Cairo-Bold"
    }

    static func register() {
        for name in ["Cairo-Regular", "Cairo-Medium", "Cairo-SemiBold", "Cairo-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }

    static let display = font(30, .bold)
    static let h1 = font(25, .bold)
    static let h2 = font(19, .bold)
    static let h3 = font(15, .semibold)
    static let body = font(13, .regular)
    static let bodyLarge = font(14.5, .regular)
    static let small = font(11.5)
    static let caption = font(10)
    static let label = font(11.5, .semibold)
}

enum TOAArt {
    static func image(_ name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
    static var symbolGold: NSImage? { image("TOASymbolGold") }
    static var symbolWhite: NSImage? { image("TOASymbolWhite") }
    static var appIcon: NSImage? { image("TOAAppIcon") }
}

/// The app symbol — used as supplied, never redrawn or recoloured.
struct TOASymbol: View {
    var size: CGFloat
    var white = false
    var body: some View {
        Group {
            if let img = white ? TOAArt.symbolWhite : TOAArt.symbolGold {
                Image(nsImage: img).resizable().interpolation(.high).aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "circle.hexagongrid.fill")
                    .resizable().aspectRatio(contentMode: .fit)
                    .foregroundStyle(ToaColor.brandGold)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// macOS 27 glass surface. Liquid Glass when the SDK/OS supports it,
/// otherwise the same shape with the approved material.
struct GlassCard: ViewModifier {
    var radius: CGFloat = 18
    var tint: Color? = nil
    var interactive = false
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            let glass: Glass = tint.map { .regular.tint($0) } ?? .regular
            content
                .background(ToaColor.surface.opacity(0.62), in: .rect(cornerRadius: radius))
                .glassEffect(interactive ? glass.interactive() : glass, in: .rect(cornerRadius: radius))
                .overlay {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(ToaColor.border, lineWidth: 1)
                }
                .shadow(color: scheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05),
                        radius: 10, y: 4)
        } else {
            content
                .background(.regularMaterial, in: .rect(cornerRadius: radius))
                .overlay {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(ToaColor.border, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
    }
}

extension View {
    func glassCard(radius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassCard(radius: radius, tint: tint, interactive: interactive))
    }
}

/// TOA selected state: gold text on UI green.
struct TOASelectPill: View {
    let title: String
    var icon: String? = nil
    let isOn: Bool
    var action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                }
                Text(title).font(TOAFont.font(11, isOn ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isOn ? ToaColor.Gold.s200 : ToaColor.textSecondary)
            .padding(.horizontal, 9)
            .frame(minHeight: 28)
            .background(
                Capsule().fill(isOn ? (scheme == .dark ? ToaColor.Green.s800 : ToaColor.brandUiGreen)
                                     : ToaColor.surface.opacity(0.55))
            )
            .overlay {
                Capsule().strokeBorder(isOn ? .clear : ToaColor.border, lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// TOA primary button (gold, green label) — at most one per screen.
struct TOAMainButtonStyle: ButtonStyle {
    var small = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TOAFont.font(small ? 12.5 : 14, .bold))
            .padding(.horizontal, small ? 14 : 20)
            .frame(minHeight: small ? 32 : 40)
            .foregroundStyle(ToaColor.brandUiGreen)
            .background(Capsule().fill(ToaColor.brandGold))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .contentShape(Capsule())
    }
}

struct TOAGreenButtonStyle: ButtonStyle {
    var small = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TOAFont.font(small ? 12 : 13.5, .semibold))
            .padding(.horizontal, small ? 12 : 18)
            .frame(minHeight: small ? 30 : 38)
            .foregroundStyle(scheme == .dark ? ToaColor.brandIvory : .white)
            .background(Capsule().fill(scheme == .dark ? ToaColor.Green.s700 : ToaColor.brandUiGreen))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .contentShape(Capsule())
    }
}

struct TOASecondaryButtonStyle: ButtonStyle {
    var small = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    @State private var hover = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TOAFont.font(small ? 12 : 13.5, .semibold))
            .padding(.horizontal, small ? 12 : 18)
            .frame(minHeight: small ? 30 : 38)
            .foregroundStyle(ToaColor.textPrimary)
            .background(Capsule().fill(ToaColor.surface.opacity(scheme == .dark ? 0.4 : 0.6)))
            .overlay {
                Capsule().strokeBorder(hover ? ToaColor.brandGold : ToaColor.border, lineWidth: 1.2)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .contentShape(Capsule())
            .onHover { hover = $0 }
    }
}

extension ButtonStyle where Self == TOAMainButtonStyle {
    static var toaMain: TOAMainButtonStyle { TOAMainButtonStyle() }
    static func toaMain(small: Bool) -> TOAMainButtonStyle { TOAMainButtonStyle(small: small) }
}
extension ButtonStyle where Self == TOAGreenButtonStyle {
    static var toaGreen: TOAGreenButtonStyle { TOAGreenButtonStyle() }
    static func toaGreen(small: Bool) -> TOAGreenButtonStyle { TOAGreenButtonStyle(small: small) }
}
extension ButtonStyle where Self == TOASecondaryButtonStyle {
    static var toaSecondary: TOASecondaryButtonStyle { TOASecondaryButtonStyle() }
    static func toaSecondary(small: Bool) -> TOASecondaryButtonStyle { TOASecondaryButtonStyle(small: small) }
}
