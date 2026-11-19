import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("الإعدادات")
                        .font(TOAFont.display)
                        .foregroundStyle(ToaColor.textPrimary)
                    Text("مجلد الحفظ وحالة الأدوات على جهازك.")
                        .font(TOAFont.bodyLarge)
                        .foregroundStyle(ToaColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("مجلد التنزيل", systemImage: "folder")
                        .font(TOAFont.label)
                        .foregroundStyle(ToaColor.textPrimary)
                    HStack {
                        Text(model.downloadFolder.path)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                        Spacer()
                        Button("تغيير") { model.changeFolder() }
                            .buttonStyle(.toaSecondary(small: true))
                        Button("فتح") { NSWorkspace.shared.open(model.downloadFolder) }
                            .buttonStyle(.toaGreen(small: true))
                    }
                }
                .padding(15)
                .glassCard(radius: 16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("الأدوات", systemImage: "wrench.and.screwdriver")
                            .font(TOAFont.label)
                            .foregroundStyle(ToaColor.textPrimary)
                        Spacer()
                        Button("إعادة الفحص") { Task { await model.checkTools() } }
                            .buttonStyle(.toaSecondary(small: true))
                    }
                    ForEach(["yt-dlp", "ffmpeg", "ffprobe", "deno", "aria2c"], id: \.self) { tool in
                        HStack(spacing: 10) {
                            Image(systemName: Tools.find(tool) != nil ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(Tools.find(tool) != nil ? ToaColor.success
                                                 : (tool == "aria2c" ? ToaColor.textSecondary : ToaColor.warning))
                            Text(tool)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundStyle(ToaColor.textPrimary)
                            Spacer()
                            Text(Tools.find(tool) != nil ? "مثبت" : (tool == "aria2c" ? "اختياري" : "ناقص"))
                                .font(TOAFont.caption)
                                .foregroundStyle(ToaColor.textSecondary)
                        }
                    }
                }
                .padding(15)
                .glassCard(radius: 16)

                VStack(alignment: .leading, spacing: 8) {
                    Label("الخصوصية", systemImage: "hand.raised")
                        .font(TOAFont.label)
                        .foregroundStyle(ToaColor.textPrimary)
                    Text("يعمل التطبيق محليًا تمامًا. لا حسابات، لا تتبّع، ولا تُرسل بياناتك لأي خادم. الاتصالات فقط إلى يوتيوب لجلب الفيديو، وإلى npm لمكوّن yt-dlp الرسمي عند الحاجة.")
                        .font(TOAFont.small)
                        .foregroundStyle(ToaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(15)
                .glassCard(radius: 16)

                HStack {
                    Text("YouTube Max · TOA · نسخة الواجهة ١٫٠")
                        .font(TOAFont.caption)
                        .foregroundStyle(ToaColor.textSecondary.opacity(0.8))
                    Spacer()
                    Text("مبني على yt-dlp وFFmpeg")
                        .font(TOAFont.caption)
                        .foregroundStyle(ToaColor.textSecondary.opacity(0.8))
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
