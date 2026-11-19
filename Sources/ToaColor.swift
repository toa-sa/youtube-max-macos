// Design tokens — colours for light and dark appearance.
// Usage: Text("…").foregroundStyle(ToaColor.textPrimary) · .background(ToaColor.background)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum ToaColor {
    // Light/dark pairs: follow the system appearance.
    public static let background = adaptive(light: Color(.sRGB, red: 0.9804, green: 0.9804, blue: 0.9686, opacity: 1),
                                        dark: Color(.sRGB, red: 0.0078, green: 0.0588, blue: 0.0392, opacity: 1))
    public static let surface = adaptive(light: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1),
                                        dark: Color(.sRGB, red: 0.0118, green: 0.1529, blue: 0.0941, opacity: 1))
    public static let surfaceSunken = adaptive(light: Color(.sRGB, red: 0.9490, green: 0.9529, blue: 0.9373, opacity: 1),
                                        dark: Color(.sRGB, red: 0.0196, green: 0.2000, blue: 0.1294, opacity: 1))
    public static let textPrimary = adaptive(light: Color(.sRGB, red: 0.1216, green: 0.1647, blue: 0.1529, opacity: 1),
                                        dark: Color(.sRGB, red: 0.9882, green: 0.9765, blue: 0.9490, opacity: 1))
    public static let textSecondary = adaptive(light: Color(.sRGB, red: 0.3569, green: 0.4000, blue: 0.3882, opacity: 1),
                                        dark: Color(.sRGB, red: 0.9882, green: 0.9765, blue: 0.9490, opacity: 0.62))
    public static let border = adaptive(light: Color(.sRGB, red: 0.8863, green: 0.8980, blue: 0.8784, opacity: 1),
                                        dark: Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 0.22))
    public static let accent = adaptive(light: Color(.sRGB, red: 0.0510, green: 0.2314, blue: 0.1804, opacity: 1),
                                        dark: Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1))
    public static let accentText = adaptive(light: Color(.sRGB, red: 0.5412, green: 0.4157, blue: 0.1176, opacity: 1),
                                        dark: Color(.sRGB, red: 0.8863, green: 0.7412, blue: 0.3843, opacity: 1))
    public static let gold = adaptive(light: Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1),
                                        dark: Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1))
    public static let success = adaptive(light: Color(.sRGB, red: 0.1176, green: 0.4784, blue: 0.3098, opacity: 1),
                                        dark: Color(.sRGB, red: 0.2471, green: 0.7098, blue: 0.4784, opacity: 1))
    public static let warning = adaptive(light: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1),
                                        dark: Color(.sRGB, red: 0.9490, green: 0.6510, blue: 0.3529, opacity: 1))
    public static let error = adaptive(light: Color(.sRGB, red: 0.7059, green: 0.1373, blue: 0.0941, opacity: 1),
                                        dark: Color(.sRGB, red: 0.9490, green: 0.5216, blue: 0.4784, opacity: 1))
    public static let info = adaptive(light: Color(.sRGB, red: 0.1686, green: 0.3725, blue: 0.5412, opacity: 1),
                                        dark: Color(.sRGB, red: 0.4980, green: 0.6980, blue: 0.8667, opacity: 1))

    // Brand (same in both modes). Logo colours are reference only: never recolour the symbol.
    public static let logoSymbolGreen = Color(.sRGB, red: 0.0196, green: 0.2000, blue: 0.1294, opacity: 1)
    public static let logoSymbolGold = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
    public static let brandUiGreen = Color(.sRGB, red: 0.0510, green: 0.2314, blue: 0.1804, opacity: 1)
    public static let brandGold = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
    public static let brandGoldInk = Color(.sRGB, red: 0.5412, green: 0.4157, blue: 0.1176, opacity: 1)
    public static let brandIvory = Color(.sRGB, red: 0.9882, green: 0.9765, blue: 0.9490, opacity: 1)
    public static let brandIconTile = Color(.sRGB, red: 0.9176, green: 0.9451, blue: 0.9294, opacity: 1)

    // Motion palettes (green and ivory).
    public enum Video {
        public enum Green {
            public static let bg = Color(.sRGB, red: 0.0510, green: 0.2314, blue: 0.1804, opacity: 1)
            public static let deep = Color(.sRGB, red: 0.0314, green: 0.1647, blue: 0.1255, opacity: 1)
            public static let text = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1)
            public static let ink = Color(.sRGB, red: 0.9059, green: 0.9373, blue: 0.9137, opacity: 1)
            public static let gold = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
            public static let goldL = Color(.sRGB, red: 0.8902, green: 0.7608, blue: 0.4784, opacity: 1)
            public static let goldT = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
            public static let onGold = Color(.sRGB, red: 0.0314, green: 0.1647, blue: 0.1255, opacity: 1)
        }
        public enum Ivory {
            public static let bg = Color(.sRGB, red: 0.9882, green: 0.9765, blue: 0.9490, opacity: 1)
            public static let deep = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1)
            public static let text = Color(.sRGB, red: 0.0510, green: 0.2314, blue: 0.1804, opacity: 1)
            public static let ink = Color(.sRGB, red: 0.1216, green: 0.1647, blue: 0.1529, opacity: 1)
            public static let gold = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
            public static let goldL = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
            public static let goldT = Color(.sRGB, red: 0.5412, green: 0.4157, blue: 0.1176, opacity: 1)
            public static let onGold = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1)
        }
    }

    // Scales 50–950. Text on light: 600 or darker. Text on dark: 500 or lighter.
    public enum Green {
        public static let s50 = Color(.sRGB, red: 0.8824, green: 1.0000, blue: 0.9529, opacity: 1)
        public static let s100 = Color(.sRGB, red: 0.7961, green: 0.9686, blue: 0.9020, opacity: 1)
        public static let s200 = Color(.sRGB, red: 0.6824, green: 0.9020, blue: 0.8196, opacity: 1)
        public static let s300 = Color(.sRGB, red: 0.5373, green: 0.8118, blue: 0.7137, opacity: 1)
        public static let s400 = Color(.sRGB, red: 0.3922, green: 0.7059, blue: 0.6000, opacity: 1)
        public static let s500 = Color(.sRGB, red: 0.2588, green: 0.5961, blue: 0.4941, opacity: 1)
        public static let s600 = Color(.sRGB, red: 0.1451, green: 0.4902, blue: 0.3922, opacity: 1)
        public static let s700 = Color(.sRGB, red: 0.0510, green: 0.3922, blue: 0.3059, opacity: 1)
        public static let s800 = Color(.sRGB, red: 0.0157, green: 0.2980, blue: 0.2275, opacity: 1)
        public static let s900 = Color(.sRGB, red: 0.0510, green: 0.2314, blue: 0.1804, opacity: 1)
        public static let s950 = Color(.sRGB, red: 0.0196, green: 0.2000, blue: 0.1294, opacity: 1)
    }
    public enum Gold {
        public static let s50 = Color(.sRGB, red: 1.0000, green: 0.9647, blue: 0.8941, opacity: 1)
        public static let s100 = Color(.sRGB, red: 1.0000, green: 0.9137, blue: 0.7412, opacity: 1)
        public static let s200 = Color(.sRGB, red: 0.9490, green: 0.8314, blue: 0.5843, opacity: 1)
        public static let s300 = Color(.sRGB, red: 0.8706, green: 0.7216, blue: 0.4118, opacity: 1)
        public static let s400 = Color(.sRGB, red: 0.7804, green: 0.6039, blue: 0.1804, opacity: 1)
        public static let s500 = Color(.sRGB, red: 0.6588, green: 0.4980, blue: 0.0549, opacity: 1)
        public static let s600 = Color(.sRGB, red: 0.5412, green: 0.4157, blue: 0.1176, opacity: 1)
        public static let s700 = Color(.sRGB, red: 0.4275, green: 0.3137, blue: 0.0118, opacity: 1)
        public static let s800 = Color(.sRGB, red: 0.3216, green: 0.2353, blue: 0.0118, opacity: 1)
        public static let s900 = Color(.sRGB, red: 0.2235, green: 0.1569, blue: 0.0000, opacity: 1)
        public static let s950 = Color(.sRGB, red: 0.1294, green: 0.0863, blue: 0.0000, opacity: 1)
    }
    public enum Night {
        public static let s50 = Color(.sRGB, red: 0.9490, green: 0.9686, blue: 1.0000, opacity: 1)
        public static let s100 = Color(.sRGB, red: 0.8745, green: 0.9294, blue: 1.0000, opacity: 1)
        public static let s200 = Color(.sRGB, red: 0.7529, green: 0.8549, blue: 0.9843, opacity: 1)
        public static let s300 = Color(.sRGB, red: 0.6353, green: 0.7529, blue: 0.9098, opacity: 1)
        public static let s400 = Color(.sRGB, red: 0.5098, green: 0.6431, blue: 0.8157, opacity: 1)
        public static let s500 = Color(.sRGB, red: 0.4000, green: 0.5333, blue: 0.7098, opacity: 1)
        public static let s600 = Color(.sRGB, red: 0.3020, green: 0.4314, blue: 0.5961, opacity: 1)
        public static let s700 = Color(.sRGB, red: 0.2235, green: 0.3412, blue: 0.4863, opacity: 1)
        public static let s800 = Color(.sRGB, red: 0.1569, green: 0.2549, blue: 0.3765, opacity: 1)
        public static let s900 = Color(.sRGB, red: 0.1020, green: 0.1725, blue: 0.2627, opacity: 1)
        public static let s950 = Color(.sRGB, red: 0.0549, green: 0.0980, blue: 0.1529, opacity: 1)
    }
    public enum Sand {
        public static let s50 = Color(.sRGB, red: 1.0000, green: 0.9647, blue: 0.9059, opacity: 1)
        public static let s100 = Color(.sRGB, red: 0.9686, green: 0.9137, blue: 0.8275, opacity: 1)
        public static let s200 = Color(.sRGB, red: 0.9020, green: 0.8353, blue: 0.7294, opacity: 1)
        public static let s300 = Color(.sRGB, red: 0.8118, green: 0.7333, blue: 0.6039, opacity: 1)
        public static let s400 = Color(.sRGB, red: 0.7059, green: 0.6196, blue: 0.4784, opacity: 1)
        public static let s500 = Color(.sRGB, red: 0.6000, green: 0.5137, blue: 0.3686, opacity: 1)
        public static let s600 = Color(.sRGB, red: 0.4902, green: 0.4078, blue: 0.2706, opacity: 1)
        public static let s700 = Color(.sRGB, red: 0.3961, green: 0.3216, blue: 0.1961, opacity: 1)
        public static let s800 = Color(.sRGB, red: 0.3020, green: 0.2392, blue: 0.1333, opacity: 1)
        public static let s900 = Color(.sRGB, red: 0.2078, green: 0.1608, blue: 0.0824, opacity: 1)
        public static let s950 = Color(.sRGB, red: 0.1176, green: 0.0902, blue: 0.0431, opacity: 1)
    }

    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light) })
        #else
        return light
        #endif
    }
}
