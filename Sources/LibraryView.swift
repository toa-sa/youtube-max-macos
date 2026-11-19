import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""

    private var items: [DownloadJob] {
        let base = model.jobs.filter { !$0.isActive }
        guard !query.isEmpty else { return base }
        return base.filter { $0.video.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("مكتبتي")
                        .font(TOAFont.display)
                        .foregroundStyle(ToaColor.textPrimary)
                    Text("كل ما نزّلته على هذا الجهاز، مع الحالة والمجلد.")
                        .font(TOAFont.bodyLarge)
                        .foregroundStyle(ToaColor.textSecondary)
                }
                Spacer()
                TextField("بحث بالعنوان", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                Button("فتح المجلد") {
                    NSWorkspace.shared.open(model.downloadFolder)
                }
                .buttonStyle(.toaSecondary)
            }

            if !items.isEmpty {
                finishedSummary
            }

            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(items) { job in
                            LibraryRow(job: job)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(maxWidth: 980, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var finishedSummary: some View {
        let done = items.filter { $0.state == .finished }.count
        return HStack(spacing: 14) {
            StatTile(value: "\(done)", label: "ملف مكتمل", symbol: "checkmark.seal")
            StatTile(value: "\(items.count - done)", label: "غير مكتمل", symbol: "exclamationmark.circle")
            StatTile(value: model.downloadFolder.lastPathComponent, label: "المجلد الحالي", symbol: "folder")
            Spacer()
            if items.contains(where: { !$0.isActive && $0.state != .finished }) {
                Button("إزالة غير المكتمل") { model.clearFinished() }
                    .buttonStyle(.toaSecondary(small: true))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            TOASymbol(size: 72)
                .opacity(0.9)
            Text("لا توجد تنزيلات بعد")
                .font(TOAFont.h2)
                .foregroundStyle(ToaColor.textPrimary)
            Text("ابدأ من «تنزيل جديد» وستظهر الملفات هنا.")
                .font(TOAFont.small)
                .foregroundStyle(ToaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 70)
    }
}

struct StatTile: View {
    let value: String, label: String, symbol: String
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ToaColor.accentText)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(TOAFont.font(14, .bold))
                    .foregroundStyle(ToaColor.textPrimary)
                    .lineLimit(1)
                Text(label)
                    .font(TOAFont.font(9.5))
                    .foregroundStyle(ToaColor.textSecondary)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .glassCard(radius: 13)
    }
}

struct LibraryRow: View {
    @Environment(AppModel.self) private var model
    let job: DownloadJob

    var body: some View {
        HStack(spacing: 14) {
            Thumbnail(url: job.video.thumbnail)
                .frame(width: 104, height: 59)
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(job.video.title)
                    .font(TOAFont.font(12.5, .medium))
                    .foregroundStyle(ToaColor.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 7) {
                    PlatformBadge(platform: job.video.resolvedPlatform)
                    Text(job.profile.name)
                    Text("·")
                    Text(job.quality == .maximum ? "أقصى جودة" : job.quality.short)
                    Text("·")
                    Text(job.video.channel)
                    if let finished = job.finishedAt {
                        Text("·")
                        Text(finished.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .font(TOAFont.caption)
                .foregroundStyle(ToaColor.textSecondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)
            StateBadge(state: job.state)

            if job.isActive {
                Button("إلغاء") { model.cancel(job) }
                    .buttonStyle(.toaSecondary(small: true))
            } else {
                Button("فتح") { model.open(job) }
                    .buttonStyle(.toaGreen(small: true))
                    .disabled(job.state != .finished)
                Button("إظهار") { model.reveal(job) }
                    .buttonStyle(.toaSecondary(small: true))
            }
        }
        .padding(11)
        .glassCard(radius: 14)
    }
}
