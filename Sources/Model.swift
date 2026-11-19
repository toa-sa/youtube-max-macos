import Foundation
import Observation
import AppKit

enum MediaProfile: String, CaseIterable, Identifiable, Codable {
    case originalMKV, appleMP4, maxMP4, audioM4A

    var id: String { rawValue }

    var name: String {
        switch self {
        case .originalMKV: "Original-MKV"
        case .appleMP4: "Apple-MP4"
        case .maxMP4: "Max-MP4"
        case .audioM4A: "Audio-M4A"
        }
    }

    var title: String {
        switch self {
        case .originalMKV: "MKV · أعلى جودة أصلية"
        case .appleMP4: "MP4 · متوافق مع QuickTime"
        case .maxMP4: "MP4 · أعلى جودة متاحة"
        case .audioM4A: "صوت فقط · M4A"
        }
    }

    var subtitle: String {
        switch self {
        case .originalMKV: "يحفظ ترميز المصدر كما هو، والأنسب لمشغل IINA."
        case .appleMP4: "H.264 وAAC، يفتح على كل أجهزة Apple لكن قد يحدّ الجودة."
        case .maxMP4: "أفضل ترميز متاح داخل MP4، قد لا يعمل على QuickTime."
        case .audioM4A: "يستخرج الصوت فقط ويحوّله إلى AAC عند الحاجة."
        }
    }

    var symbol: String {
        switch self {
        case .originalMKV: "film.stack"
        case .appleMP4: "play.rectangle"
        case .maxMP4: "sparkles.tv"
        case .audioM4A: "waveform"
        }
    }

    var shortTitle: String {
        switch self {
        case .originalMKV: "MKV · أصلي"
        case .appleMP4: "MP4 · متوافق"
        case .maxMP4: "MP4 · أقصى"
        case .audioM4A: "M4A · صوت"
        }
    }

    var shortHint: String {
        switch self {
        case .originalMKV: "أفضل جودة · IINA"
        case .appleMP4: "H.264 · QuickTime"
        case .maxMP4: "أعلى ترميز"
        case .audioM4A: "صوت فقط"
        }
    }

    var fileExtension: String {
        switch self {
        case .audioM4A: "m4a"
        case .originalMKV: "mkv"
        case .appleMP4, .maxMP4: "mp4"
        }
    }

    var isAudio: Bool { self == .audioM4A }
}

enum QualityCap: Int, CaseIterable, Identifiable, Codable {
    case maximum = 0, k4320 = 4320, k2160 = 2160, k1440 = 1440
    case k1080 = 1080, k720 = 720, k480 = 480, k360 = 360

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .maximum: "الأقصى المتاح"
        case .k4320: "8K · 4320p"
        case .k2160: "4K · 2160p"
        case .k1440: "2K · 1440p"
        case .k1080: "Full HD · 1080p"
        case .k720: "HD · 720p"
        case .k480: "480p"
        case .k360: "360p"
        }
    }
    var short: String { self == .maximum ? "الأقصى" : "\(rawValue)p" }
    var shortLabel: String {
        switch self {
        case .maximum: "أقصى"
        case .k4320: "8K"
        case .k2160: "4K"
        case .k1440: "2K"
        case .k1080: "1080"
        case .k720: "720"
        case .k480: "480"
        case .k360: "360"
        }
    }
}

enum DownloadSpeed: Int, CaseIterable, Identifiable, Codable {
    case balanced = 4, fast = 8, turbo = 16
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .balanced: "متوازن"
        case .fast: "سريع"
        case .turbo: "توربو"
        }
    }
    var detail: String {
        switch self {
        case .balanced: "٤ أجزاء متوازية"
        case .fast: "٨ أجزاء متوازية"
        case .turbo: "١٦ جزءًا + aria2c"
        }
    }
}

struct VideoInfo: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let title: String
    let channel: String
    let duration: Int
    let thumbnail: URL?
    let viewCount: Int?
    let heights: [Int]
}

struct DownloadJob: Identifiable, Equatable, Sendable, Codable {
    enum State: Equatable, Sendable, Codable {
        case queued, preparing, downloading, processing, finished, failed(String), cancelled
    }
    var id = UUID()
    var video: VideoInfo
    var profile: MediaProfile
    var quality: QualityCap
    var speed: DownloadSpeed
    var state: State = .queued
    var progress: Double = 0
    var detail: String = ""
    var outputPath: String?
    var startedAt = Date()
    var finishedAt: Date?

    var isActive: Bool {
        switch state {
        case .queued, .preparing, .downloading, .processing: true
        default: false
        }
    }
}

@Observable
@MainActor
final class AppModel {
    var urlText = ""
    var info: VideoInfo?
    var isInspecting = false
    var inspectError: String?
    var profile: MediaProfile = .originalMKV
    var quality: QualityCap = .maximum
    var speed: DownloadSpeed = .fast
    var jobs: [DownloadJob] = []
    var toolsReady = false
    var toolsDetail = "جارٍ الفحص…"
    var downloadFolder: URL
    var toast: String?

    @ObservationIgnored private var active: [UUID: DownloadRunner] = [:]
    @ObservationIgnored private var history: [DownloadJob] = []

    init() {
        let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies")
        downloadFolder = movies.appendingPathComponent("YouTube Downloads", isDirectory: true)
        loadHistory()
    }

    var activeJobs: [DownloadJob] { jobs.filter(\.isActive) }
    var finishedJobs: [DownloadJob] {
        jobs.filter { !$0.isActive }.sorted { ($0.finishedAt ?? $0.startedAt) > ($1.finishedAt ?? $1.startedAt) }
    }

    func start() async {
        await checkTools()
        try? FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
        if let arg = CommandLine.arguments.dropFirst().first(where: { $0.hasPrefix("https://") }) {
            urlText = arg
            await inspect()
        }
    }

    func checkTools() async {
        let report = await Tools.report()
        toolsReady = report.ready
        toolsDetail = report.text
        if !report.ready { toast = report.text }
    }

    // MARK: - Inspecting

    func inspect() async {
        guard let id = VideoID.parse(urlText) else {
            inspectError = "الرابط غير صالح. الصق رابط فيديو واحد من يوتيوب."
            info = nil
            return
        }
        isInspecting = true
        inspectError = nil
        defer { isInspecting = false }
        do {
            let result = try await Metadata.fetch(id: id)
            info = result
            if !result.heights.isEmpty, quality != .maximum, !result.heights.contains(quality.rawValue) {
                // keep the user's choice; the menu disables unavailable caps
            }
        } catch {
            info = nil
            inspectError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func pasteFromClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        urlText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await inspect() }
    }

    // MARK: - Downloads

    func enqueue() {
        guard let info else { return }
        let job = DownloadJob(video: info, profile: profile, quality: quality, speed: speed)
        jobs.insert(job, at: 0)
        start(job)
    }

    func retry(_ job: DownloadJob) {
        var copy = job
        copy.id = UUID()
        copy.state = .queued
        copy.progress = 0
        copy.detail = ""
        copy.outputPath = nil
        copy.startedAt = Date()
        copy.finishedAt = nil
        jobs.insert(copy, at: 0)
        start(copy)
    }

    private func start(_ job: DownloadJob) {
        let runner = DownloadRunner(job: job, folder: downloadFolder) { [weak self] update in
            Task { @MainActor in self?.apply(update) }
        }
        active[job.id] = runner
        runner.start()
    }

    private func apply(_ update: DownloadUpdate) {
        guard let idx = jobs.firstIndex(where: { $0.id == update.id }) else { return }
        jobs[idx].state = update.state
        if let p = update.progress { jobs[idx].progress = p }
        if let d = update.detail { jobs[idx].detail = d }
        if let path = update.outputPath { jobs[idx].outputPath = path }

        if !jobs[idx].isActive {
            jobs[idx].finishedAt = Date()
            active[jobs[idx].id] = nil
            history.removeAll { $0.id == jobs[idx].id }
            history.insert(jobs[idx], at: 0)
            saveHistory()
        }
    }

    func cancel(_ job: DownloadJob) {
        active[job.id]?.cancel()
    }

    func reveal(_ job: DownloadJob) {
        let target = job.outputPath.map { URL(fileURLWithPath: $0) } ?? downloadFolder
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }

    func open(_ job: DownloadJob) {
        guard let path = job.outputPath else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func clearFinished() {
        jobs.removeAll { !$0.isActive }
        history = jobs
        saveHistory()
    }

    func changeFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "اختيار"
        panel.directoryURL = downloadFolder
        if panel.runModal() == .OK, let url = panel.url { downloadFolder = url }
    }

    // MARK: - History (only paths & titles, no network)

    private var historyURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("YouTubeMax", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    private func saveHistory() {
        let keep = Array(history.prefix(80))
        guard let data = try? JSONEncoder().encode(keep) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let saved = try? JSONDecoder().decode([DownloadJob].self, from: data) else { return }
        history = saved
        jobs = saved
    }
}

enum VideoID {
    static func parse(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("https://"), !text.contains(" "), !text.contains("\\"),
              let comps = URLComponents(string: text),
              let host = comps.host?.lowercased() else { return nil }
        let allowed: Set<String> = [
            "youtu.be", "youtube.com", "www.youtube.com", "m.youtube.com",
            "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"
        ]
        guard allowed.contains(host) else { return nil }
        var candidate: String?
        if host == "youtu.be" {
            candidate = comps.path.split(separator: "/").first.map(String.init)
        } else if comps.path == "/watch" {
            candidate = comps.queryItems?.first(where: { $0.name == "v" })?.value
        } else {
            let parts = comps.path.split(separator: "/").map(String.init)
            if parts.count >= 2, ["shorts", "live", "embed", "v"].contains(parts[0]) { candidate = parts[1] }
        }
        guard let id = candidate, id.count == 11,
              id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        return id
    }
}

enum Tools {
    struct Report: Sendable { let ready: Bool; let text: String }

    static func find(_ name: String) -> String? {
        let paths = ["/opt/homebrew/bin/\(name)", "/usr/local/bin/\(name)", "/usr/bin/\(name)"]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func report() async -> Report {
        let required = ["yt-dlp", "ffmpeg", "ffprobe", "deno"]
        let missing = required.filter { find($0) == nil }
        if missing.isEmpty {
            return Report(ready: true, text: "كل الأدوات جاهزة: yt-dlp، FFmpeg، Deno.")
        }
        return Report(ready: false, text: "ناقص: \(missing.joined(separator: "، ")). ثبّتها بالأمر: brew install \(missing.filter { $0 != "ffprobe" }.joined(separator: " "))")
    }
}
