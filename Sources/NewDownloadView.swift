import SwiftUI

struct NewDownloadView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var urlFocused: Bool
    @State private var showLoader = false

    var body: some View {
        Group {
            if model.info != nil || !model.activeJobs.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 13) {
                        header
                        linkCard
                        if let info = model.info {
                            HStack(alignment: .top, spacing: 13) {
                                PreviewCard(info: info)
                                    .frame(width: 268)
                                OptionsCard(info: info)
                            }
                            .transition(.opacity)
                        } else if model.isInspecting {
                            InspectingCard()
                        } else if let error = model.inspectError {
                            ErrorCard(message: error)
                        }
                        if !model.activeJobs.isEmpty { ActiveJobsCard() }
                        recentSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .frame(maxWidth: 980, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                VStack(alignment: .leading, spacing: 13) {
                    header
                    linkCard
                    if model.isInspecting {
                        InspectingCard()
                    } else if let error = model.inspectError {
                        ErrorCard(message: error)
                    }
                    StartGuide()
                    if !model.finishedJobs.isEmpty {
                        recentSection
                    } else {
                        QuickFacts()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .frame(maxWidth: 980, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .animation(.smooth(duration: 0.3), value: model.info?.id)
        .animation(.smooth(duration: 0.25), value: model.activeJobs.count)
        .onAppear { urlFocused = true }
        .overlay {
            if showLoader {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).opacity(0.3)
                    ToaColor.brandIvory.opacity(0.88)
                    TOALoader(label: "يجهّز…", progress: nil, size: 168, onGreen: false)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
        }
        .task(id: model.isInspecting) {
            if model.isInspecting {
                try? await Task.sleep(for: .milliseconds(600))
                if model.isInspecting { showLoader = true }
            } else {
                showLoader = false
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("نزّل ما تريد مشاهدته")
                    .font(TOAFont.display)
                    .foregroundStyle(ToaColor.textPrimary)
                Text("YouTube · X · Facebook — الصق الرابط، اختر الصيغة، ويُحفظ الملف على جهازك.")
                    .font(TOAFont.bodyLarge)
                    .foregroundStyle(ToaColor.textSecondary)
            }
            Spacer()
            if model.info != nil {
                Label("تم التحقق", systemImage: "checkmark.circle.fill")
                    .font(TOAFont.font(10.5, .medium))
                    .foregroundStyle(ToaColor.success)
            }
        }
    }

    private var linkCard: some View {
        HStack(spacing: 8) {
            TextField("", text: Binding(get: { model.urlText }, set: { model.urlText = $0 }))
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(ToaColor.textPrimary)
                .environment(\.layoutDirection, .leftToRight)
                .multilineTextAlignment(.leading)
                .overlay(alignment: .leading) {
                    if model.urlText.isEmpty {
                        Text("الصق رابط YouTube أو X أو Facebook…")
                            .font(TOAFont.font(12))
                            .foregroundStyle(ToaColor.textSecondary.opacity(0.7))
                            .environment(\.layoutDirection, .rightToLeft)
                            .allowsHitTesting(false)
                    }
                }
                .focused($urlFocused)
                .onSubmit { Task { await model.inspect() } }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(ToaColor.surface.opacity(0.55), in: .rect(cornerRadius: 11))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(urlFocused ? ToaColor.brandGold : ToaColor.border, lineWidth: urlFocused ? 1.4 : 1)
                }
                .disabled(model.isInspecting)
                .accessibilityLabel("رابط فيديو يوتيوب")

            Button {
                model.pasteFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18, height: 20)
            }
            .buttonStyle(.toaSecondary)
            .help("لصق من الحافظة")

            Button {
                Task { await model.inspect() }
            } label: {
                if model.isInspecting {
                    TOALoaderMini()
                } else {
                    Label("تحقق", systemImage: "magnifyingglass")
                        .font(TOAFont.font(12.5, .semibold))
                }
            }
            .buttonStyle(.toaGreen)
            .disabled(model.urlText.isEmpty || model.isInspecting)
        }
        .padding(11)
        .glassCard(radius: 16)
    }

    @ViewBuilder
    private var recentSection: some View {
        let recent = Array(model.finishedJobs.prefix(3))
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("آخر التنزيلات")
                        .font(TOAFont.h3)
                        .foregroundStyle(ToaColor.textPrimary)
                    Spacer()
                    Button("الكل") { }
                        .buttonStyle(.link)
                        .font(.system(size: 10.5))
                        .hidden()
                }
                ForEach(recent) { job in
                    CompactJobRow(job: job)
                }
            }
            .padding(12)
            .glassCard(radius: 14)
        } else if model.info == nil {
            HStack(spacing: 8) {
                Image(systemName: "tray")
                    .foregroundStyle(ToaColor.textSecondary.opacity(0.7))
                Text("ستظهر تنزيلاتك الأخيرة هنا بعد أول ملف.")
                    .font(TOAFont.small)
                    .foregroundStyle(ToaColor.textSecondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }
}

private struct LoaderDot: View {
    @State private var spin = false
    var body: some View {
        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spin)
            .onAppear { spin = true }
    }
}

struct PreviewCard: View {
    let info: VideoInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Thumbnail(url: info.thumbnail, platform: info.resolvedPlatform)
                .frame(height: 138)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 10))

            Text(info.title)
                .font(TOAFont.font(13, .semibold))
                .foregroundStyle(ToaColor.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    PlatformBadge(platform: info.resolvedPlatform)
                    Text(info.channel)
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    if info.duration > 0 {
                        Label(info.duration.videoClock, systemImage: "clock")
                    }
                    if let views = info.viewCount {
                        Label(views.shortCount, systemImage: "eye")
                    }
                }
            }
            .font(TOAFont.caption)
            .foregroundStyle(ToaColor.textSecondary)

            if !info.heights.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(info.heights.prefix(5).enumerated()), id: \.offset) { _, h in
                        Text("\(h)p")
                            .font(TOAFont.font(9, .medium))
                            .monospacedDigit()
                            .foregroundStyle(ToaColor.accentText)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(ToaColor.brandGold.opacity(0.14), in: .capsule)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(11)
        .glassCard(radius: 14)
    }
}

struct Thumbnail: View {
    let url: URL?
    var platform: Platform = .youtube
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            Rectangle().fill(.quaternary.opacity(0.45))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                fallback
            }
        }
        .clipped()
        .task(id: url) {
            guard let url else { return }
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15",
                             forHTTPHeaderField: "User-Agent")
            request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
            guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }
            image = NSImage(data: data)
        }
    }

    private var fallback: some View {
        VStack(spacing: 4) {
            Image(systemName: platform == .facebook ? "video.badge.plus"
                  : (platform == .x ? "at" : "play.rectangle"))
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(ToaColor.textSecondary.opacity(0.55))
            Text(platform.title)
                .font(TOAFont.font(9, .medium))
                .foregroundStyle(ToaColor.textSecondary.opacity(0.7))
        }
    }
}

struct InspectingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            TOASymbol(size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("نقرأ بيانات الفيديو…")
                    .font(TOAFont.font(12.5, .semibold))
                    .foregroundStyle(ToaColor.textPrimary)
                Text("لحظات ويظهر العنوان والجودات المتاحة.")
                    .font(TOAFont.caption)
                    .foregroundStyle(ToaColor.textSecondary)
            }
            Spacer()
        }
        .padding(13)
        .glassCard(radius: 14)
    }
}

struct ErrorCard: View {
    let message: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(ToaColor.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("تعذّر تحضير الفيديو")
                    .font(TOAFont.font(12, .semibold))
                    .foregroundStyle(ToaColor.textPrimary)
                Text(message)
                    .font(TOAFont.small)
                    .foregroundStyle(ToaColor.textSecondary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .padding(13)
        .glassCard(radius: 14)
    }
}

struct ActiveJobsCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("قيد التنزيل")
                .font(TOAFont.h3)
                .foregroundStyle(ToaColor.textPrimary)
            ForEach(model.activeJobs) { job in
                JobRow(job: job, compact: false)
            }
        }
        .padding(12)
        .glassCard(radius: 14)
    }
}

struct StartGuide: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ToaColor.accentText)
                    Text("كيف تبدأ؟")
                        .font(TOAFont.h3)
                        .foregroundStyle(ToaColor.textPrimary)
                }
                step(1, "انسخ رابط المنشور", "YouTube · X · Facebook — منشور واحد عام")
                step(2, "الصقه في الحقل واضغط تحقق", "ستظهر معاينة الفيديو والجودات المتاحة.")
                step(3, "اختر الصيغة والجودة ثم ابدأ", "يُحفظ الملف في مجلد الأفلام على جهازك.")
                Text("Instagram يحتاج تسجيل دخول لكل المحتوى تقريبًا، لذلك لا يدعمه التطبيق.")
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 10))
                        .foregroundStyle(ToaColor.success)
                    Text("محلي بالكامل · بلا حسابات أو تتبّع")
                        .font(TOAFont.caption)
                        .foregroundStyle(ToaColor.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .glassCard(radius: 16)

            VStack(alignment: .leading, spacing: 10) {
                Text("الصيغ")
                    .font(TOAFont.label)
                    .foregroundStyle(ToaColor.textSecondary)
                formatRow("film.stack", "Original-MKV", "أعلى جودة أصلية، الأفضل لـIINA")
                formatRow("play.rectangle", "Apple-MP4", "H.264 وAAC، يعمل على QuickTime")
                formatRow("sparkles.tv", "Max-MP4", "أعلى ترميز داخل MP4")
                formatRow("waveform", "Audio-M4A", "الصوت فقط بصيغة AAC")
                Divider().overlay(ToaColor.border)
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("~/Movies/YouTube Downloads")
                        .environment(\.layoutDirection, .leftToRight)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(TOAFont.font(9.5))
                .foregroundStyle(ToaColor.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(width: 300, alignment: .topLeading)
            .glassCard(radius: 16)
        }
    }

    private func step(_ n: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(TOAFont.font(11, .bold))
                .monospacedDigit()
                .foregroundStyle(ToaColor.brandUiGreen)
                .frame(width: 22, height: 22)
                .background(Circle().fill(ToaColor.brandGold.opacity(0.85)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TOAFont.font(12.5, .semibold))
                    .foregroundStyle(ToaColor.textPrimary)
                Text(detail)
                    .font(TOAFont.small)
                    .foregroundStyle(ToaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formatRow(_ icon: String, _ name: String, _ detail: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(ToaColor.accentText)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(ToaColor.textPrimary)
                Text(detail)
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

struct QuickFacts: View {
    var body: some View {
        HStack(spacing: 10) {
            fact("speedometer", "سرعات متوازية", "4 أو 8 أو 16 جزءًا")
            fact("4k.tv", "حتى 8K", "بحدّ أعلى تختاره")
            fact("arrow.triangle.2.circlepath", "استكمال", "يكمل الملف الناقص")
            fact("lock.shield", "محلي", "بلا حسابات أو تتبّع")
        }
    }

    private func fact(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ToaColor.accentText)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(TOAFont.font(10.5, .semibold))
                    .foregroundStyle(ToaColor.textPrimary)
                Text(detail)
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .glassCard(radius: 12)
    }
}

struct JobRow: View {
    @Environment(AppModel.self) private var model
    let job: DownloadJob
    var compact: Bool

    var body: some View {
        HStack(spacing: 10) {
            Thumbnail(url: job.video.thumbnail, platform: job.video.resolvedPlatform)
                .frame(width: compact ? 66 : 84, height: compact ? 37 : 47)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(job.video.title)
                        .font(TOAFont.font(11.5, .medium))
                        .foregroundStyle(ToaColor.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    StateBadge(state: job.state)
                }

                if job.isActive {
                    ProgressView(value: job.progress)
                        .progressViewStyle(.linear)
                        .tint(ToaColor.brandGold)
                        .controlSize(.small)
                    HStack(spacing: 6) {
                        Text(job.detail.isEmpty ? "…" : job.detail)
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(Int(job.progress * 100))٪")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(job.profile.name)
                        Text("·")
                        Text(job.quality == .maximum ? "أقصى جودة" : job.quality.short)
                        Spacer()
                        if job.state == .finished {
                            Button("فتح") { model.open(job) }
                                .buttonStyle(.link).font(.system(size: 10))
                            Button("إظهار") { model.reveal(job) }
                                .buttonStyle(.link).font(.system(size: 10))
                        }
                    }
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary)
                }
            }

            if job.isActive {
                Button {
                    model.cancel(job)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("إلغاء التنزيل")
            }
        }
        .padding(7)
        .background(ToaColor.surface.opacity(0.45), in: .rect(cornerRadius: 9))
    }
}

struct CompactJobRow: View {
    @Environment(AppModel.self) private var model
    let job: DownloadJob

    var body: some View {
        HStack(spacing: 9) {
            Thumbnail(url: job.video.thumbnail, platform: job.video.resolvedPlatform)
                .frame(width: 54, height: 30)
                .clipShape(.rect(cornerRadius: 5))
            Text(job.video.title)
                .font(TOAFont.font(11))
                .foregroundStyle(ToaColor.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(job.profile.name)
                .font(TOAFont.font(9))
                .foregroundStyle(ToaColor.textSecondary.opacity(0.75))
            StateBadge(state: job.state)
            if job.state == .finished {
                Button {
                    model.open(job)
                } label: {
                    Image(systemName: "play.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(ToaColor.accentText)
                }
                .buttonStyle(.plain)
                .help("فتح الملف")
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(ToaColor.surface.opacity(0.4), in: .rect(cornerRadius: 8))
    }
}

struct PlatformBadge: View {
    let platform: Platform

    var body: some View {
        Text(platform.short)
            .font(TOAFont.font(8.5, .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(color.opacity(0.14), in: .capsule)
            .overlay { Capsule().strokeBorder(color.opacity(0.35), lineWidth: 0.8) }
    }

    private var color: Color {
        switch platform {
        case .youtube: Color(red: 0.80, green: 0.16, blue: 0.14)
        case .x: ToaColor.textPrimary
        case .facebook: Color(red: 0.09, green: 0.36, blue: 0.75)
        case .instagram: Color(red: 0.60, green: 0.24, blue: 0.55)
        }
    }
}

struct StateBadge: View {
    let state: DownloadJob.State

    var body: some View {
        Label(label, systemImage: icon)
            .font(TOAFont.font(8.5, .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: .capsule)
    }

    private var label: String {
        switch state {
        case .queued: "بالانتظار"
        case .preparing: "تجهيز"
        case .downloading: "تنزيل"
        case .processing: "معالجة"
        case .finished: "جاهز"
        case .failed: "فشل"
        case .cancelled: "ملغى"
        }
    }
    private var icon: String {
        switch state {
        case .finished: "checkmark"
        case .failed: "exclamationmark"
        case .cancelled: "slash"
        default: "arrow.down"
        }
    }
    private var color: Color {
        switch state {
        case .finished: ToaColor.success
        case .failed: ToaColor.error
        case .cancelled: ToaColor.textSecondary
        default: ToaColor.accentText
        }
    }
}

extension Int {
    var videoClock: String {
        let h = self / 3600, m = (self % 3600) / 60, s = self % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
    var shortCount: String {
        switch self {
        case 1_000_000...: String(format: "%.1fM", Double(self) / 1_000_000)
        case 1_000...: String(format: "%.1fK", Double(self) / 1_000)
        default: "\(self)"
        }
    }
}
