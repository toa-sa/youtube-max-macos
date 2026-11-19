import SwiftUI

struct OptionsCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    let info: VideoInfo

    private let profileColumns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                label("الصيغة", icon: "film")
                Spacer()
                if !model.profile.isAudio {
                    Text("الجودة تحدّ الأعلى، ولا تكبّر الفيديو.")
                        .font(TOAFont.font(9.5))
                        .foregroundStyle(ToaColor.textSecondary.opacity(0.85))
                }
            }

            LazyVGrid(columns: profileColumns, spacing: 6) {
                ForEach(MediaProfile.allCases) { item in
                    ProfileTile(profile: item, selected: model.profile == item) {
                        model.profile = item
                    }
                }
            }

            if !model.profile.isAudio {
                Divider().overlay(ToaColor.border).padding(.vertical, 1)
                label("أعلى جودة", icon: "4k.tv")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                    ForEach(QualityCap.allCases) { cap in
                        let available = cap == .maximum || info.heights.contains(cap.rawValue)
                        QualityTile(cap: cap, selected: model.quality == cap, available: available) {
                            model.quality = cap
                        }
                    }
                }
            }

            Divider().overlay(ToaColor.border).padding(.vertical, 1)

            HStack(spacing: 8) {
                label("السرعة", icon: "speedometer")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(DownloadSpeed.allCases) { speed in
                        TOASelectPill(title: speed.title, isOn: model.speed == speed) {
                            model.speed = speed
                        }
                        .help(speed.detail)
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    model.enqueue()
                } label: {
                    Label("ابدأ التنزيل", systemImage: "arrow.down.to.line.compact")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.toaMain)
                .keyboardShortcut(.return, modifiers: [.command])

                Button {
                    model.info = nil
                    model.urlText = ""
                } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.toaSecondary)
                .help("مسح")
            }

            HStack(spacing: 5) {
                Image(systemName: "folder")
                Text(model.downloadFolder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(TOAFont.font(9.5))
            .foregroundStyle(ToaColor.textSecondary.opacity(0.8))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 16)
    }

    private func label(_ title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ToaColor.accentText)
            Text(title)
                .font(TOAFont.label)
                .foregroundStyle(ToaColor.textPrimary)
        }
    }
}

struct ProfileTile: View {
    let profile: MediaProfile
    let selected: Bool
    var action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: profile.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selected ? ToaColor.Gold.s200 : ToaColor.accentText)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.shortTitle)
                        .font(TOAFont.font(10.5, .semibold))
                        .foregroundStyle(selected ? ToaColor.Gold.s200 : ToaColor.textPrimary)
                    Text(profile.shortHint)
                        .font(TOAFont.font(8.5))
                        .foregroundStyle(selected ? ToaColor.Gold.s200.opacity(0.85) : ToaColor.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? (scheme == .dark ? ToaColor.Green.s800 : ToaColor.brandUiGreen)
                                   : ToaColor.surface.opacity(0.5))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? .clear : ToaColor.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(profile.title)
    }
}

struct QualityTile: View {
    let cap: QualityCap
    let selected: Bool
    let available: Bool
    var action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Text(cap.shortLabel)
                .font(TOAFont.font(9.5, selected ? .semibold : .medium))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .foregroundStyle(
                    !available ? ToaColor.textSecondary.opacity(0.45)
                    : (selected ? ToaColor.Gold.s200 : ToaColor.textSecondary)
                )
                .background(
                    Capsule().fill(selected
                        ? (scheme == .dark ? ToaColor.Green.s800 : ToaColor.brandUiGreen)
                        : ToaColor.surface.opacity(0.45))
                )
                .overlay {
                    Capsule().strokeBorder(selected ? .clear : ToaColor.border.opacity(0.8), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .help(available ? cap.label : "غير متاح في هذا الفيديو")
    }
}
