import SwiftUI

@main
struct YouTubeMaxApp: App {
    @State private var model = AppModel()

    init() { TOAFont.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(minWidth: 880, minHeight: 560)
                .tint(ToaColor.brandGold)
                .background(TOAWindowBackground())
        }
        .defaultSize(width: 1010, height: 632)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("فحص الأدوات") { Task { await model.checkTools() } }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

enum Section: String, CaseIterable, Identifiable {
    case download, library, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .download: "تنزيل جديد"
        case .library: "مكتبتي"
        case .settings: "الإعدادات"
        }
    }
    var symbol: String {
        switch self {
        case .download: "arrow.down.to.line"
        case .library: "square.stack"
        case .settings: "gearshape"
        }
    }
}

struct TOAWindowBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            ToaColor.background
            if let texture = TOAArt.image("TOABackground") {
                Image(nsImage: texture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(scheme == .dark ? 0.55 : 0.42)
                    .blur(radius: 0.5)
            } else {
                LinearGradient(
                    colors: scheme == .dark
                        ? [ToaColor.Green.s950, ToaColor.background]
                        : [ToaColor.brandIvory, ToaColor.Green.s50.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var section: Section = .download
    @Namespace private var nav

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 214)
            Divider().opacity(0.35)
            ZStack {
                switch section {
                case .download: NewDownloadView()
                case .library: LibraryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaPadding(.top, 10)
        .background(.clear)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await model.checkTools() }
                } label: {
                    Label("فحص الأدوات", systemImage: "stethoscope")
                }
                .help("التحقق من yt-dlp وFFmpeg وDeno")
            }
        }
        .task { await model.start() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                TOASymbol(size: 30)
                VStack(alignment: .leading, spacing: -1) {
                    Text("يوتيوب ماكس")
                        .font(TOAFont.font(14, .bold))
                        .foregroundStyle(ToaColor.textPrimary)
                    Text("TOA · تنزيل الفيديو")
                        .font(TOAFont.caption)
                        .foregroundStyle(ToaColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 14)

            VStack(spacing: 3) {
                ForEach(Section.allCases) { item in
                    navRow(item)
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 7) {
                Divider().opacity(0.4)
                HStack(spacing: 6) {
                    Circle()
                        .fill(model.toolsReady ? ToaColor.success : ToaColor.warning)
                        .frame(width: 6, height: 6)
                    Text(model.toolsReady ? "الأدوات جاهزة" : "تحقق من الأدوات")
                        .font(TOAFont.caption)
                        .foregroundStyle(ToaColor.textSecondary)
                }
                Text(model.downloadFolder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(ToaColor.surface.opacity(scheme == .dark ? 0.28 : 0.45))
    }

    private func navRow(_ item: Section) -> some View {
        let on = section == item
        return Button {
            withAnimation(.smooth(duration: 0.25)) { section = item }
        } label: {
            HStack(spacing: 9) {
                if on {
                    Capsule()
                        .fill(ToaColor.brandGold)
                        .frame(width: 3, height: 16)
                } else {
                    Color.clear.frame(width: 3, height: 16)
                }
                Image(systemName: item.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(item.title)
                    .font(TOAFont.font(12.5, on ? .semibold : .medium))
                Spacer(minLength: 0)
                if item == .library, !model.jobs.isEmpty {
                    Text(verbatim: "\(model.jobs.count)")
                        .font(TOAFont.font(9.5, .semibold))
                        .monospacedDigit()
                        .foregroundStyle(on ? ToaColor.brandUiGreen : ToaColor.accentText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(on ? ToaColor.Gold.s200 : ToaColor.brandGold.opacity(0.16), in: .capsule)
                }
            }
            .foregroundStyle(on ? ToaColor.Gold.s200 : ToaColor.textSecondary)
            .padding(.horizontal, 8)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(on ? (scheme == .dark ? ToaColor.Green.s800 : ToaColor.brandUiGreen)
                             : Color.clear)
            )
            .contentShape(.rect(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
