import SwiftUI

/// App loader.
/// The symbol breathes on brand green; a gold light draws it from the right, holds,
/// erases and redraws. Two gold arcs turn around it (1.8 s), a thinner one back (2.7 s).
/// Under it: a status word (Cairo SemiBold) and the percentage in Arabic digits, fixed width.
struct TOALoader: View {
    var label: String
    var progress: Double?
    var size: CGFloat = 200
    var onGreen = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            VStack(spacing: size * 0.24) {
                TOALoaderMark(time: t, slow: reduceMotion, onGreen: onGreen)
                    .frame(width: size, height: size)
                VStack(spacing: 1) {
                    Text(label)
                        .font(TOAFont.font(max(14, size * 0.10), .semibold))
                        .foregroundStyle(onGreen ? ToaColor.brandIvory : ToaColor.textPrimary)
                    if let progress {
                        Text(verbatim: Self.arabicPercent(progress))
                            .font(TOAFont.font(max(12, size * 0.08), .semibold))
                            .monospacedDigit()
                            .foregroundStyle((onGreen ? ToaColor.Gold.s200 : ToaColor.accentText).opacity(0.92))
                    }
                }
                .shadow(color: onGreen ? .clear : .black.opacity(0.35), radius: 5, y: 1)
            }
            .padding(.horizontal, 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progress.map { "\(label) \(Self.arabicPercent($0))" } ?? label)
        .onAppear { start = Date() }
    }

    static func arabicPercent(_ p: Double) -> String {
        let digits = Array("٠١٢٣٤٥٦٧٨٩")
        let n = String(Int((min(1, max(0, p)) * 100).rounded(.down)))
        return String(n.map { digits[Int(String($0))!] }) + "٪"
    }
}

struct TOALoaderMark: View {
    let time: Double
    var slow = false
    var onGreen = true

    static let gold = ToaColor.brandGold
    static let glow = ToaColor.Gold.s100
    static let trace = ToaColor.Gold.s200

    private static func ease(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let breathPeriod = slow ? 6.0 : 2.6
            let breath = 1 + 0.06 * (0.5 - 0.5 * cos(time * 2 * .pi / breathPeriod))
            let cycle = time.truncatingRemainder(dividingBy: 4.2)
            let drawing = cycle < 2.6
            let k = drawing ? Self.ease(cycle / 2.6) : (cycle < 3.1 ? 1 : Self.ease((cycle - 3.1) / 1.1))
            let drawn = drawing ? k : (cycle < 3.1 ? 1 : 1 - k)

            ZStack {
                // The app mark: official TOA symbol on the brand's green tile.
                ZStack {
                    RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                        .fill(ToaColor.brandUiGreen)
                    TOASymbol(size: s * 0.62, white: true)
                        .opacity(drawn > 0.02 ? 0.30 : 0.75)

                    // The gold light drawing the symbol from the right.
                    if drawn > 0.004 {
                        TOASymbol(size: s * 0.62, white: true)
                            .overlay { highlight }
                            .mask(alignment: .trailing) {
                                Rectangle()
                                    .frame(width: max(1, s * 0.68 * drawn))
                                    .blur(radius: 0.3)
                            }
                            .shadow(color: Self.trace.opacity(0.85), radius: s * 0.035)
                    }
                }
                .frame(width: s, height: s)
                .overlay {
                    RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                        .strokeBorder(ToaColor.brandGold.opacity(0.35), lineWidth: max(0.6, s * 0.004))
                }
                .shadow(color: .black.opacity(onGreen ? 0.28 : 0.16), radius: s * 0.06, y: s * 0.02)
                .scaleEffect(breath)

                // Arcs: two with points every 1.8 s, a thinner one the other way every 2.7 s.
                TOAArcs(thin: false, strong: !onGreen)
                    .rotationEffect(.radians(time * 2 * .pi / (slow ? 6 : 1.8)))
                    .frame(width: s * 1.42, height: s * 1.42)
                TOAArcs(thin: true, strong: !onGreen)
                    .rotationEffect(.radians(-time * 2 * .pi / (slow ? 6 : 2.7)))
                    .frame(width: s * 1.42, height: s * 1.42)
                    .opacity(0.9)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var highlight: some View {
        LinearGradient(
            colors: [Self.glow, Self.trace, Self.gold],
            startPoint: .bottomLeading, endPoint: .topTrailing
        )
        .blendMode(.sourceAtop)
    }
}

/// The arcs, in a 200-unit box.
struct TOAArcs: View {
    let thin: Bool
    /// Light backgrounds get the deeper brand gold so the arcs read as clearly as on green.
    var strong = false
    private var arcColor: Color { strong ? ToaColor.brandGoldInk : TOALoaderMark.gold }
    private var dotColor: Color { strong ? ToaColor.Gold.s500 : TOALoaderMark.glow }

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 200
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            if thin {
                var p = Path()
                p.addArc(center: pt(100, 100), radius: 90 * k,
                         startAngle: .degrees(180), endAngle: .degrees(240), clockwise: false)
                ctx.stroke(p, with: .color(arcColor.opacity(strong ? 0.75 : 0.55)),
                           style: StrokeStyle(lineWidth: (strong ? 1.7 : 1.4) * k, lineCap: .round))
                ctx.fill(Path(ellipseIn: CGRect(x: 55 * k - 2.6 * k, y: 22 * k - 2.6 * k,
                                                width: 5.2 * k, height: 5.2 * k)),
                         with: .color(dotColor.opacity(0.95)))
            } else {
                for (a, dot) in [(270.0, pt(181, 53)), (90.0, pt(19, 147))] {
                    var p = Path()
                    p.addArc(center: pt(100, 100), radius: 94 * k,
                             startAngle: .degrees(a), endAngle: .degrees(a + 59.5), clockwise: false)
                    ctx.stroke(p, with: .color(arcColor.opacity(strong ? 1 : 0.9)),
                               style: StrokeStyle(lineWidth: (strong ? 2.8 : 2.4) * k, lineCap: .round))
                    ctx.fill(Path(ellipseIn: CGRect(x: dot.x - 4 * k, y: dot.y - 4 * k,
                                                    width: 8 * k, height: 8 * k)),
                             with: .color(dotColor))
                }
            }
        }
    }
}

/// Small (~24 pt) version for inline waits — same mark, no percentage.
struct TOALoaderMini: View {
    var label: String?
    var size: CGFloat = 22
    @State private var start = Date()
    var body: some View {
        HStack(spacing: 6) {
            TimelineView(.animation) { timeline in
                TOALoaderMark(time: timeline.date.timeIntervalSince(start), slow: false)
                    .frame(width: size, height: size)
            }
            if let label {
                Text(label)
                    .font(TOAFont.font(10.5))
                    .foregroundStyle(ToaColor.textSecondary)
            }
        }
        .onAppear { start = Date() }
    }
}
