import Foundation

struct DownloadUpdate: Sendable {
    let id: UUID
    var state: DownloadJob.State
    var progress: Double?
    var detail: String?
    var outputPath: String?
}

enum EngineError: LocalizedError {
    case missingTool(String)
    case badMetadata
    case notAVideo
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingTool(let name): "الأداة \(name) غير مثبتة."
        case .badMetadata: "تعذّر قراءة بيانات الفيديو."
        case .notAVideo: "لم نجد مقطعًا في هذا الرابط."
        case .failed(let message): message
        }
    }
}

enum Metadata {
    static func fetch(link: ParsedLink) async throws -> VideoInfo {
        guard let ytdlp = Tools.find("yt-dlp") else { throw EngineError.missingTool("yt-dlp") }
        let url = link.url.absoluteString
        let output = try await ProcessRunner.run(
            ytdlp,
            ["--ignore-config", "--no-playlist", "--no-warnings", "--skip-download",
             "--no-config-locations", "--dump-single-json", "--", url],
            timeout: 90
        )
        guard output.status == 0 else {
            throw EngineError.failed(processMessage(output.stderr))
        }
        guard let data = output.stdout.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EngineError.badMetadata
        }
        guard let videoID = root["id"] as? String else { throw EngineError.notAVideo }
        let entries = root["entries"] as? [[String: Any]] ?? []
        guard entries.count <= 1 else {
            throw EngineError.failed("هذا الرابط يحتوي أكثر من مقطع. الصق رابط منشور واحد.")
        }
        let item = entries.first ?? root
        guard let title = (item["title"] as? String) ?? (item["description"] as? String) else {
            throw EngineError.notAVideo
        }
        let titleText = title
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? title
        let heights = (item["formats"] as? [[String: Any]] ?? [])
            .compactMap { $0["height"] as? Int }
            .filter { $0 > 0 }
        let unique = Array(Set(heights)).sorted(by: >)
        let thumbList = item["thumbnails"] as? [[String: Any]] ?? []
        let thumbString = (item["thumbnail"] as? String)
            ?? thumbList.compactMap { $0["url"] as? String }.last
            ?? (item["thumbnail"] as? String)
        let channel = (item["uploader"] as? String)
            ?? (item["channel"] as? String)
            ?? (item["uploader_id"] as? String)
            ?? link.platform.title
        let duration = (item["duration"] as? Int)
            ?? (item["duration"] as? Double).map(Int.init)
            ?? 0
        return VideoInfo(
            id: videoID,
            title: titleText,
            channel: channel,
            duration: duration,
            thumbnail: thumbString.flatMap(URL.init(string:)),
            viewCount: (item["view_count"] as? Int) ?? (item["like_count"] as? Int),
            heights: unique,
            pageURL: link.url,
            platform: link.platform
        )
    }

    static func processMessage(_ stderr: String) -> String {
        let lines = stderr.split(separator: "\n").map(String.init)
        let meaningful = lines.last { line in
            !line.hasPrefix("[debug]") && !line.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return meaningful?.replacingOccurrences(of: "ERROR: ", with: "") ?? "فشل تنفيذ yt-dlp."
    }
}

struct ProcessOutput: Sendable {
    let status: Int32
    let stdout: String
    let stderr: String
}

enum ProcessRunner {
    static func run(_ path: String, _ args: [String], timeout: TimeInterval) async throws -> ProcessOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        process.environment = env
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        process.standardInput = FileHandle.nullDevice

        try process.run()

        let box = PipeBox()
        let group = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: group) {
            box.out = out.fileHandleForReading.readDataToEndOfFile()
        }
        DispatchQueue.global(qos: .utility).async(group: group) {
            box.err = err.fileHandleForReading.readDataToEndOfFile()
        }
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning, Date() < deadline {
            try await Task.sleep(for: .milliseconds(120))
        }
        if process.isRunning {
            process.terminate()
            try? await Task.sleep(for: .milliseconds(400))
            if process.isRunning { process.interrupt() }
            throw EngineError.failed("انتهت مهلة الاتصال. تحقق من الشبكة وحاول مرة أخرى.")
        }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            group.notify(queue: .global()) { c.resume() }
        }
        return ProcessOutput(
            status: process.terminationStatus,
            stdout: String(data: box.out, encoding: .utf8) ?? "",
            stderr: String(data: box.err, encoding: .utf8) ?? ""
        )
    }

    private final class PipeBox: @unchecked Sendable {
        var out = Data(), err = Data()
    }
}

final class DownloadRunner: @unchecked Sendable {
    private let job: DownloadJob
    private let folder: URL
    private let onUpdate: @Sendable (DownloadUpdate) -> Void
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false

    init(job: DownloadJob, folder: URL, onUpdate: @escaping @Sendable (DownloadUpdate) -> Void) {
        self.job = job
        self.folder = folder
        self.onUpdate = onUpdate
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let running = process
        lock.unlock()
        running?.terminate()
    }

    func start() {
        let job = job
        let folder = folder
        let onUpdate = onUpdate
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.execute(job: job, folder: folder, emit: onUpdate)
        }
    }

    private func execute(job: DownloadJob, folder: URL, emit emitIn: @escaping @Sendable (DownloadUpdate) -> Void) async {
        let emit = emitIn
        func send(_ state: DownloadJob.State, _ progress: Double? = nil, _ detail: String? = nil, _ path: String? = nil) {
            emit(DownloadUpdate(id: job.id, state: state, progress: progress, detail: detail, outputPath: path))
        }

        guard let ytdlp = Tools.find("yt-dlp") else {
            send(.failed("yt-dlp غير مثبت. ثبّته بالأمر: brew install yt-dlp"), 0, "أداة ناقصة")
            return
        }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        send(.preparing, 0, "تجهيز التنزيل…")

        let args = arguments(for: job, folder: folder)
        let handle = Process()
        handle.executableURL = URL(fileURLWithPath: ytdlp)
        handle.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        handle.environment = env
        handle.standardInput = FileHandle.nullDevice
        let outPipe = Pipe(), errPipe = Pipe()
        handle.standardOutput = outPipe
        handle.standardError = errPipe
        lock.lock()
        process = handle
        lock.unlock()

        do {
            try handle.run()
        } catch {
            lock.lock(); process = nil; lock.unlock()
            send(.failed(error.localizedDescription), 0, "تعذّر التشغيل")
            return
        }

        let emitter = UpdateEmitter { state, progress, detail, path in
            emit(DownloadUpdate(id: job.id, state: state, progress: progress,
                                detail: detail, outputPath: path))
        }
        let outTask = Task.detached(priority: .utility) {
            do {
                for try await line in outPipe.fileHandleForReading.bytes.lines {
                    await emitter.handle(line: line)
                }
            } catch {
                await emitter.handle(line: "ERROR: انقطعت قراءة مخرجات التنزيل.")
            }
        }
        let errTask = Task.detached(priority: .utility) {
            do {
                for try await line in errPipe.fileHandleForReading.bytes.lines {
                    await emitter.handle(line: line)
                }
            } catch {
                // The pipe closes when the process ends; nothing else to report.
            }
        }

        handle.waitUntilExit()
        _ = await outTask.value
        _ = await errTask.value
        let status = handle.terminationStatus
        lock.lock()
        process = nil
        let wasCancelled = cancelled
        lock.unlock()

        if wasCancelled {
            send(.cancelled, nil, "أُلغي التنزيل")
            return
        }
        if status == 0 {
            let path = await emitter.finalPath
            if let path, FileManager.default.fileExists(atPath: path),
               (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue ?? 0 > 0 {
                send(.finished, 1, "اكتمل التنزيل", path)
            } else {
                send(.failed("لم يتم العثور على الملف النهائي في مجلد التنزيل."), 0, "فشل التحقق")
            }
        } else {
            let message = await emitter.lastError
            send(.failed(message ?? "فشل التنزيل (رمز \(status))."), 0, "لم يكتمل")
        }
    }

    private func arguments(for job: DownloadJob, folder: URL) -> [String] {
        var args = [
            "--ignore-config", "--no-playlist", "--no-overwrites", "--continue",
            "--remote-components", "ejs:npm",
            "--retries", "10", "--fragment-retries", "10", "--extractor-retries", "3",
            "--abort-on-unavailable-fragments",
            "--concurrent-fragments", String(job.speed.rawValue),
            "--no-simulate", "--newline", "--progress",
            "--progress-template",
            "download:YTMAXPROGRESS|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.speed)s|%(progress.eta)s",
            "--print", "after_move:YTMAXFILE:%(filepath)s",
            "--embed-metadata", "--no-embed-info-json",
            "-P", folder.path
        ]

        let height = job.quality.rawValue > 0 ? "[height<=\(job.quality.rawValue)]" : ""
        let format: String
        switch job.profile {
        case .audioM4A:
            format = "ba[ext=m4a]/ba/b"
            args += ["-f", format, "--extract-audio", "--audio-format", "m4a"]
        case .appleMP4:
            format = "bv[vcodec^=avc1]\(height)+ba[acodec^=mp4a]/b[ext=mp4][vcodec^=avc1][acodec^=mp4a]\(height)"
            args += ["--merge-output-format", "mp4", "--remux-video", "mp4", "-f", format]
        case .maxMP4:
            format = "bv\(height)+ba/b\(height)"
            args += ["--merge-output-format", "mp4", "--remux-video", "mp4", "-f", format]
        case .originalMKV:
            format = "bv\(height)+ba/b\(height)"
            args += ["--merge-output-format", "mkv", "--remux-video", "mkv", "-f", format]
        }

        // Only YouTube reliably exposes height; other sites would print "NAp".
        let heightTemplate = (job.profile.isAudio || job.video.resolvedPlatform != .youtube)
            ? "" : " [%(height)sp]"
        let template = "%(title).160B [%(id)s]\(heightTemplate) [\(job.profile.name)].%(ext)s"
        args += ["-o", template]

        if job.speed == .turbo, let aria = Tools.find("aria2c") {
            args += [
                "--downloader", aria, "--downloader", "dash,m3u8:native",
                "--downloader-args", "aria2c:-x 8 -s 8 -k 1M --max-tries=5 --retry-wait=2"
            ]
        }
        args += ["--", job.video.resolvedURL.absoluteString]
        return args
    }
}

private actor UpdateEmitter {
    private let send: @Sendable (DownloadJob.State, Double?, String?, String?) -> Void
    private(set) var lastError: String?
    private(set) var finalPath: String?
    private var lastPercent = -1.0
    private var lastStage = ""

    init(send: @escaping @Sendable (DownloadJob.State, Double?, String?, String?) -> Void) {
        self.send = send
    }

    func handle(line raw: String) async {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.hasPrefix("YTMAXPROGRESS|") {
            let parts = line.split(separator: "|", omittingEmptySubsequences: false)
            guard parts.count >= 6 else { return }
            let downloaded = Double(parts[1]) ?? 0
            let total = Double(parts[2]) ?? Double(parts[3])
            let speed = Double(parts[4])
            var fraction = 0.0
            if let total, total > 0 { fraction = min(1, downloaded / total) }
            let percent = (fraction * 1000).rounded() / 10
            guard percent != lastPercent else { return }
            lastPercent = percent
            let detail = UpdateEmitter.detail(downloaded: downloaded, total: total, speed: speed)
            send(.downloading, fraction, detail, nil)
            return
        }
        if line.hasPrefix("YTMAXFILE:") {
            finalPath = String(line.dropFirst("YTMAXFILE:".count))
            return
        }
        if line.hasPrefix("[Merger]") || line.hasPrefix("[VideoRemuxer]") || line.hasPrefix("[FixupM4a]")
            || line.hasPrefix("[ExtractAudio]") || line.hasPrefix("[Metadata]") {
            if lastStage != "processing" {
                lastStage = "processing"
                send(.processing, nil, "معالجة الملف النهائي…", nil)
            }
            return
        }
        if line.hasPrefix("ERROR:") {
            lastError = Metadata.processMessage(line)
        }
    }

    static func detail(downloaded: Double, total: Double?, speed: Double?) -> String {
        let size = ByteCountFormatter.string(fromByteCount: Int64(downloaded), countStyle: .file)
        var text = "تم تنزيل \(size)"
        if let total, total > 0 {
            text += " من \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file))"
        }
        if let speed, speed > 0 {
            text += " · \(ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file))/ث"
        }
        return text
    }
}
