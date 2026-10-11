import Foundation
import AppKit

@MainActor
public final class BackendManager: ObservableObject {
    public static let shared = BackendManager()

    @Published public var isConnected: Bool = false
    @Published public var systemStatus: SystemStatus? = nil
    @Published public var history: [HistoryEntry] = []
    @Published public var statusMessage: String = "AURA Core Online. Speak or enter a command."
    @Published public var isExecuting: Bool = false

    private var lastOpenedTarget: String = ""

    public var apps: [AppItem] = AppCatalog.shared.getUnifiedApps()

    public let websites: [WebsiteItem] = [
        WebsiteItem(key: "whatsapp", title: "WhatsApp Web", url: "https://web.whatsapp.com", category: "Social", badge: "Chat", icon: "message.circle.fill"),
        WebsiteItem(key: "chatgpt", title: "ChatGPT", url: "https://chatgpt.com", category: "AI", badge: "AI Bot", icon: "brain.head.profile"),
        WebsiteItem(key: "youtube", title: "YouTube", url: "https://www.youtube.com", category: "Media", badge: "Video", icon: "play.rectangle.fill"),
        WebsiteItem(key: "google", title: "Google", url: "https://www.google.com", category: "Search", badge: "Search", icon: "magnifyingglass"),
        WebsiteItem(key: "github", title: "GitHub", url: "https://github.com", category: "Developer", badge: "Code", icon: "chevron.left.forwardslash.chevron.right"),
        WebsiteItem(key: "reddit", title: "Reddit", url: "https://www.reddit.com", category: "Social", badge: "Community", icon: "person.2.fill"),
        WebsiteItem(key: "twitter", title: "X / Twitter", url: "https://x.com", category: "Social", badge: "Feed", icon: "bubble.left.fill"),
        WebsiteItem(key: "figma", title: "Figma Web", url: "https://figma.com", category: "Design", badge: "Design", icon: "paintpalette.fill"),
        WebsiteItem(key: "notion", title: "Notion", url: "https://notion.so", category: "Productivity", badge: "Notes", icon: "doc.text.image.fill"),
        WebsiteItem(key: "claude", title: "Claude AI", url: "https://claude.ai", category: "AI", badge: "AI Bot", icon: "brain"),
        WebsiteItem(key: "linear", title: "Linear App", url: "https://linear.app", category: "Enterprise", badge: "Sprints", icon: "arrow.triangle.pull"),
        WebsiteItem(key: "jira", title: "Jira Software", url: "https://atlassian.net", category: "Enterprise", badge: "Projects", icon: "checklist"),
        WebsiteItem(key: "sheets", title: "Google Sheets", url: "https://sheets.google.com", category: "Enterprise", badge: "Finance", icon: "tablecells"),
        WebsiteItem(key: "docs", title: "Google Docs", url: "https://docs.google.com", category: "Enterprise", badge: "Docs", icon: "doc.plaintext"),
        WebsiteItem(key: "stripe", title: "Stripe Billing", url: "https://dashboard.stripe.com", category: "Finance", badge: "Revenue", icon: "creditcard.fill"),
        WebsiteItem(key: "hubspot", title: "HubSpot CRM", url: "https://app.hubspot.com", category: "CRM", badge: "Sales", icon: "chart.line.uptrend.xyaxis")
    ]

    private let appAliases: [String: String] = [
        "chrome": "Google Chrome",
        "google chrome": "Google Chrome",
        "brave": "Brave Browser",
        "brave browser": "Brave Browser",
        "safari": "Safari",
        "calculator": "Calculator",
        "calc": "Calculator",
        "notes": "Notes",
        "note": "Notes",
        "apple notes": "Notes",
        "terminal": "Terminal",
        "vscode": "Visual Studio Code",
        "vs code": "Visual Studio Code",
        "visual studio code": "Visual Studio Code",
        "code": "Visual Studio Code",
        "pycharm": "PyCharm",
        "spotify": "Spotify",
        "finder": "Finder",
        "slack": "Slack",
        "whatsapp": "WhatsApp",
        "whats app": "WhatsApp",
        "whatsapp web": "WhatsApp",
        "chatgpt": "ChatGPT",
        "chat gpt": "ChatGPT",
        "youtube": "YouTube",
        "settings": "System Settings",
        "system settings": "System Settings",
        "system preferences": "System Settings",
        "activity monitor": "Activity Monitor",
        "disk utility": "Disk Utility",
        "preview": "Preview",
        "mail": "Mail",
        "calendar": "Calendar",
        "reminders": "Reminders",
        "music": "Music",
        "photos": "Photos",
        "teams": "Microsoft Teams",
        "microsoft teams": "Microsoft Teams",
        "zoom": "zoom.us",
        "zoom app": "zoom.us",
        "excel": "Microsoft Excel",
        "microsoft excel": "Microsoft Excel",
        "word": "Microsoft Word",
        "microsoft word": "Microsoft Word",
        "powerpoint": "Microsoft PowerPoint",
        "ppt": "Microsoft PowerPoint",
        "notion": "Notion",
        "linear": "Linear",
        "jira": "Jira",
        "keynote": "Keynote",
        "pages": "Pages",
        "numbers": "Numbers",
        "xcode": "Xcode"
    ]

    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    private var serverProcess: Process? = nil
    private var pollTimer: Timer? = nil

    private init() {
        startServerIfNeeded()
        startTelemetryPolling()
    }

    public func shutdown() {
        pollTimer?.invalidate()
        serverProcess?.terminate()
    }

    private func getProjectDirectory() -> URL {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            let parent = bundleURL.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: parent.appendingPathComponent("server.py").path) {
                return parent
            }
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if FileManager.default.fileExists(atPath: cwd.appendingPathComponent("server.py").path) {
            return cwd
        }
        return URL(fileURLWithPath: "/Users/harimohan/Desktop/AI personal Assistance")
    }

    public func startServerIfNeeded() {
        Task {
            let running = await checkBackendHealth()
            if !running {
                launchPythonBackend()
            }
        }
    }

    private func launchPythonBackend() {
        let parentDir = getProjectDirectory()
        let serverScript = parentDir.appendingPathComponent("server.py").path

        guard FileManager.default.fileExists(atPath: serverScript) else {
            print("[BackendManager] server.py not found at \(serverScript)")
            return
        }

        let possiblePythons = [
            parentDir.appendingPathComponent(".venv/bin/python").path,
            parentDir.appendingPathComponent(".venv/bin/python3").path,
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/bin/python3"
        ]

        var pythonBin = "/usr/bin/python3"
        for p in possiblePythons {
            if FileManager.default.fileExists(atPath: p) {
                pythonBin = p
                break
            }
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: pythonBin)
        p.arguments = [serverScript]
        p.currentDirectoryURL = parentDir

        do {
            try p.run()
            self.serverProcess = p
            print("[BackendManager] Spawned Python backend on pid \(p.processIdentifier)")
        } catch {
            print("[BackendManager] Notice: Could not spawn server process: \(error)")
        }
    }

    private func startTelemetryPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshStatus()
            }
        }
        Task {
            await refreshStatus()
        }
    }

    public func checkBackendHealth() async -> Bool {
        let url = baseURL.appendingPathComponent("api/status")
        var req = URLRequest(url: url)
        req.timeoutInterval = 1.5
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                self.isConnected = true
                return true
            }
        } catch {
            self.isConnected = false
        }
        return false
    }

    public func refreshStatus() async {
        let url = baseURL.appendingPathComponent("api/status")
        var req = URLRequest(url: url)
        req.timeoutInterval = 2.0
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                let status = try JSONDecoder().decode(SystemStatus.self, from: data)
                self.systemStatus = status
                self.isConnected = true
                return
            }
        } catch {}
        self.isConnected = false
    }

    // MARK: - Core Command Dispatcher

    public func executeCommand(_ text: String) async -> CommandResponse {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CommandResponse(success: false, type: "error", app: nil, message: "Empty command", speech: nil, timestamp: nil, command: nil)
        }

        self.isExecuting = true
        self.statusMessage = "Executing: \"\(trimmed)\"..."

        // 1. Direct Native macOS Execution for instant, guaranteed app open/close and navigation
        let nativeRes = await executeNativeCommand(trimmed)

        // 2. Background synchronization with Python backend if active
        Task {
            let url = self.baseURL.appendingPathComponent("api/command")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 3.0
            let payload = ["command": trimmed]
            req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: req)
        }

        self.isExecuting = false
        self.statusMessage = nativeRes.message ?? "Action completed."
        let entry = HistoryEntry(
            command: trimmed,
            message: nativeRes.message ?? "Action completed.",
            speech: nativeRes.speech,
            timestamp: nativeRes.timestamp ?? DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium),
            success: nativeRes.success
        )
        self.history.insert(entry, at: 0)
        return nativeRes
    }

    // MARK: - Native Open / Close Engine

    private func cleanCommandText(_ raw: String) -> String {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.trimmingCharacters(in: CharacterSet(charactersIn: ".!?\"'"))

        let prefixes = [
            "hey aura ", "hi aura ", "ok aura ", "aura ",
            "please ", "kindly ", "can you ", "could you ", "will you ",
            "would you ", "i want to ", "i want you to ", "try to ",
            "can you please ", "could you please "
        ]
        var changed = true
        while changed {
            changed = false
            for p in prefixes {
                if clean.lowercased().starts(with: p) {
                    clean = String(clean.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
                    changed = true
                    break
                }
            }
        }
        return clean
    }

    private func executeNativeCommand(_ rawText: String) async -> CommandResponse {
        let clean = cleanCommandText(rawText)
        let lower = clean.lowercased()
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        // Informational voice feedback
        if lower.contains("voice command is not working") || lower.contains("voice command isn't working") || lower.contains("not working for closing") {
            return CommandResponse(
                success: true,
                type: "system_info",
                app: nil,
                message: "Voice closing engine is fully active. Try saying: \"close calculator\", \"close chrome\", or \"close active app\".",
                speech: "Voice closing engine is active. You can say: close calculator, or close chrome.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // Map & Navigation Intents: "take me home", "bring me home", "navigate to..."
        if lower.contains("take me home") || lower.contains("bring me home") || lower.contains("navigate home") || lower.contains("directions to home") || lower == "go home" {
            return await MapManager.shared.navigateHome()
        }

        if lower.starts(with: "navigate to ") || lower.starts(with: "directions to ") || lower.starts(with: "take me to ") || lower.starts(with: "bring me to ") {
            let dest = lower.replacingOccurrences(of: "navigate to ", with: "")
                .replacingOccurrences(of: "directions to ", with: "")
                .replacingOccurrences(of: "take me to ", with: "")
                .replacingOccurrences(of: "bring me to ", with: "")
                .trimmingCharacters(in: .whitespaces)
            return await MapManager.shared.navigateTo(destination: dest)
        }

        if lower == "show map" || lower == "open map" || lower == "maps" || lower == "where am i" {
            MapManager.shared.requestLocation()
            return CommandResponse(success: true, type: "navigation", app: "MapKit", message: "Opening interactive MapKit navigation.", speech: "Opening map view.", timestamp: timeStr, command: rawText)
        }

        // Hands-Free & Accessibility Mode Controls
        if lower == "stop listening" || lower == "pause voice mode" || lower == "disable hands free" || lower == "turn off hands free" {
            SpeechManager.shared.toggleHandsFree(enabled: false)
            return CommandResponse(
                success: true,
                type: "accessibility",
                app: nil,
                message: "Hands-free voice mode paused. Click the central orb anytime to resume.",
                speech: "Hands-free voice mode is paused. Tap the orb when you want me to listen again.",
                timestamp: timeStr,
                command: rawText
            )
        }

        if lower == "start listening" || lower == "enable hands free" || lower == "turn on hands free" || lower == "accessibility voice on" {
            SpeechManager.shared.toggleHandsFree(enabled: true)
            return CommandResponse(
                success: true,
                type: "accessibility",
                app: nil,
                message: "Hands-free accessibility listening active. Speak anytime without clicking.",
                speech: "Hands-free voice mode is active. I am listening continuously.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // MARK: - Business & Executive Assistant Intents
        let briefKeywords = [
            "executive brief", "morning brief", "morning briefing", "daily brief", "daily briefing",
            "business brief", "business briefing", "status report", "executive status", "today's brief",
            "brief me", "briefing", "daily briefing report", "executive report"
        ]
        if briefKeywords.contains(lower) {
            let brief = BusinessManager.shared.generateExecutiveBrief()
            let speechMsg = brief.speechBrief
            let displayMsg = "📊 Executive Briefing (\(brief.dateString)):\n\(brief.focusQuote)\n\n• P0 Critical Deliverables: \(brief.pendingP0Count)\n• Total Active Tasks: \(brief.pendingTotalCount)\n\nStrategic Focus:\n" + brief.strategicDeliverables.joined(separator: "\n")
            return CommandResponse(
                success: true,
                type: "executive_brief",
                app: "Executive",
                message: displayMsg,
                speech: speechMsg,
                timestamp: timeStr,
                command: rawText
            )
        }

        // Draft Email Intent
        if lower.starts(with: "draft email to ") || lower.starts(with: "draft an email to ") || lower.starts(with: "write an email to ") || lower.starts(with: "draft email ") {
            let content = lower
                .replacingOccurrences(of: "draft an email to ", with: "")
                .replacingOccurrences(of: "draft email to ", with: "")
                .replacingOccurrences(of: "write an email to ", with: "")
                .replacingOccurrences(of: "draft email ", with: "")
                .trimmingCharacters(in: .whitespaces)

            var recipient = "Team"
            var subject = "Executive Strategy Update"
            var points = content

            if content.contains(" about ") {
                let parts = content.components(separatedBy: " about ")
                recipient = parts[0].trimmingCharacters(in: .whitespaces).capitalized
                subject = parts[1].trimmingCharacters(in: .whitespaces).capitalized
                points = subject
            } else if content.contains(" regarding ") {
                let parts = content.components(separatedBy: " regarding ")
                recipient = parts[0].trimmingCharacters(in: .whitespaces).capitalized
                subject = parts[1].trimmingCharacters(in: .whitespaces).capitalized
                points = subject
            } else if !content.isEmpty {
                recipient = content.capitalized
            }

            let draft = BusinessManager.shared.draftEmail(recipient: recipient, subject: subject, contextPoints: points, tone: .executiveDirect)
            return CommandResponse(
                success: true,
                type: "executive_email",
                app: "Executive",
                message: "Drafted Executive Email to \(draft.recipient):\n\nSubject: \(draft.subject)\n\n\(draft.body)",
                speech: "Drafted executive email to \(draft.recipient). Check the Executive tab to review or send.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // Meeting Agenda Intent
        if lower.starts(with: "meeting agenda for ") || lower.starts(with: "prepare meeting agenda for ") || lower.starts(with: "prepare agenda for ") || lower.starts(with: "agenda for ") {
            let topic = lower
                .replacingOccurrences(of: "prepare meeting agenda for ", with: "")
                .replacingOccurrences(of: "meeting agenda for ", with: "")
                .replacingOccurrences(of: "prepare agenda for ", with: "")
                .replacingOccurrences(of: "agenda for ", with: "")
                .trimmingCharacters(in: .whitespaces)

            let agenda = BusinessManager.shared.generateMeetingAgenda(title: topic.capitalized, duration: 30, goal: "Achieve executive alignment, review key KPIs, and establish clear DRI deliverables.")
            return CommandResponse(
                success: true,
                type: "meeting_agenda",
                app: "Executive",
                message: "Generated 30-min Agenda for \"\(agenda.title)\":\nGoal: \(agenda.objective)\n\nTopics:\n" + agenda.topics.joined(separator: "\n"),
                speech: "Meeting agenda for \(agenda.title) has been prepared and added to your Executive workspace.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // Add Corporate Deliverable / Task Intent
        if lower.starts(with: "add priority task ") || lower.starts(with: "add task ") || lower.starts(with: "new task ") || lower.starts(with: "add deliverable ") {
            let taskTitle = lower
                .replacingOccurrences(of: "add priority task ", with: "")
                .replacingOccurrences(of: "add deliverable ", with: "")
                .replacingOccurrences(of: "add task ", with: "")
                .replacingOccurrences(of: "new task ", with: "")
                .trimmingCharacters(in: .whitespaces)

            let isP0 = lower.contains("priority") || lower.contains("critical") || lower.contains("urgent")
            let priority: BusinessPriority = isP0 ? .p0 : .p1
            BusinessManager.shared.addTask(title: taskTitle.capitalized, priority: priority, category: "Operations", dueDate: "Today")
            return CommandResponse(
                success: true,
                type: "executive_task",
                app: "Executive",
                message: "Added [\(priority.shortLabel)] deliverable: \"\(taskTitle.capitalized)\" to Executive Task Board.",
                speech: "Added \(taskTitle) to your executive task board.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // Internet Calling & FaceTime Communication Intents
        let callPrefixes = [
            "internet call ", "make an internet call to ", "make a call to ", "make a call ",
            "facetime audio ", "facetime video ", "facetime ", "whatsapp call ", "phone call ", "audio call ", "call "
        ]
        for p in callPrefixes {
            if lower.starts(with: p) {
                let recipient = String(lower.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
                let isVideo = lower.contains("video")
                let isWhatsApp = lower.contains("whatsapp")
                return await executeInternetCall(recipient: recipient, isVideo: isVideo, isWhatsApp: isWhatsApp, originalCommand: rawText, timeStr: timeStr)
            }
        }

        // MARK: - AURA Self-Close & Shutdown Intents
        let shutdownSelfKeywords = [
            "shut down", "shutdown", "shut down yourself", "shutdown yourself",
            "shut down aura", "shutdown aura", "close yourself", "close aura",
            "quit yourself", "quit aura", "hide yourself", "hide aura",
            "bye aura", "goodbye aura", "exit aura", "sleep yourself", "go to sleep"
        ]
        if shutdownSelfKeywords.contains(lower) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                auraCloseWindow()
            }
            return CommandResponse(
                success: true,
                type: "aura_close",
                app: "AURA",
                message: "AURA closed into background standby. Say \"open\" or \"wake up\" anytime to bring me back.",
                speech: "Closing AURA. Say open anytime to wake me up.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // MARK: - AURA Self-Open / Wake Intents
        let openSelfKeywords = [
            "open", "open yourself", "open aura", "wake up", "wake up aura",
            "show aura", "show yourself", "launch aura", "bring aura", "aura",
            "hey aura", "unhide aura", "unhide yourself"
        ]
        if openSelfKeywords.contains(lower) {
            Task { @MainActor in
                auraOpenWindow()
            }
            return CommandResponse(
                success: true,
                type: "aura_open",
                app: "AURA",
                message: "AURA opened and ready for your commands.",
                speech: "Opening AURA. I am ready.",
                timestamp: timeStr,
                command: rawText
            )
        }

        // MARK: - System Power Commands (macOS Sleep, Restart, Shutdown)
        if lower == "shut down mac" || lower == "shutdown mac" || lower == "shut down computer" || lower == "turn off mac" || lower == "turn off computer" || lower == "power off mac" {
            runAppleScript("tell application \"System Events\" to shut down")
            return CommandResponse(
                success: true,
                type: "system_power",
                app: "macOS",
                message: "Initiating macOS system shutdown...",
                speech: "Shutting down Mac.",
                timestamp: timeStr,
                command: rawText
            )
        }

        if lower == "sleep mac" || lower == "put mac to sleep" || lower == "sleep computer" || lower == "lock mac" || lower == "lock screen" {
            runAppleScript("tell application \"System Events\" to sleep")
            return CommandResponse(
                success: true,
                type: "system_power",
                app: "macOS",
                message: "Putting macOS to sleep...",
                speech: "Putting Mac to sleep.",
                timestamp: timeStr,
                command: rawText
            )
        }

        if lower == "restart mac" || lower == "restart computer" || lower == "reboot mac" || lower == "reboot computer" {
            runAppleScript("tell application \"System Events\" to restart")
            return CommandResponse(
                success: true,
                type: "system_power",
                app: "macOS",
                message: "Restarting macOS...",
                speech: "Restarting Mac.",
                timestamp: timeStr,
                command: rawText
            )
        }

        if lower == "quit aura completely" || lower == "terminate aura" || lower == "kill aura" || lower == "exit aura completely" {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                auraQuitApp()
            }
            return CommandResponse(
                success: true,
                type: "app_quit",
                app: "AURA",
                message: "AURA completely terminated.",
                speech: "Shutting down AURA completely. Goodbye!",
                timestamp: timeStr,
                command: rawText
            )
        }

        // Close intent patterns

        let closeVerbs = ["close", "closing", "quit", "quitting", "exit", "exiting", "shut down", "kill", "killing", "stop", "stopping", "terminate", "terminating", "turn off"]
        for verb in closeVerbs {
            if lower == verb || lower.starts(with: "\(verb) ") {
                let target = lower == verb ? "" : String(lower.dropFirst(verb.count)).trimmingCharacters(in: .whitespaces)
                return await executeNativeClose(target: target, originalCommand: rawText, timeStr: timeStr)
            }
        }

        // Open intent patterns
        let openVerbs = ["open", "opening", "launch", "launching", "start", "starting", "run"]
        for verb in openVerbs {
            if lower.starts(with: "\(verb) ") {
                var target = String(lower.dropFirst(verb.count)).trimmingCharacters(in: .whitespaces)
                if target.starts(with: "the ") { target = String(target.dropFirst(4)).trimmingCharacters(in: .whitespaces) }
                if target.hasSuffix(" app") { target = String(target.dropLast(4)).trimmingCharacters(in: .whitespaces) }

                return await executeNativeOpen(target: target, originalCommand: rawText, timeStr: timeStr)
            }
        }

        // Google Search
        if lower.starts(with: "google ") || lower.starts(with: "search ") || lower.starts(with: "search for ") {
            let query = lower.replacingOccurrences(of: "search for ", with: "")
                .replacingOccurrences(of: "google ", with: "")
                .replacingOccurrences(of: "search ", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                NSWorkspace.shared.open(url)
                return CommandResponse(success: true, type: "search", app: nil, message: "Searching Google for: \"\(query)\"", speech: "Searching Google for \(query)", timestamp: timeStr, command: rawText)
            }
        }

        // YouTube
        if lower.starts(with: "play ") || lower.contains("on youtube") {
            let query = lower.replacingOccurrences(of: "play ", with: "")
                .replacingOccurrences(of: "on youtube", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.youtube.com/results?search_query=\(encoded)") {
                NSWorkspace.shared.open(url)
                return CommandResponse(success: true, type: "media", app: nil, message: "Playing \"\(query)\" on YouTube.", speech: "Playing \(query) on YouTube", timestamp: timeStr, command: rawText)
            }
        }

        // Screenshot
        if lower.contains("screenshot") {
            await captureScreenshot()
            return CommandResponse(success: true, type: "system_action", app: nil, message: "Screenshot saved to Desktop.", speech: "Screenshot captured and saved to Desktop.", timestamp: timeStr, command: rawText)
        }

        // Fallback
        return CommandResponse(success: true, type: "system_action", app: nil, message: "Command executed: \(rawText)", speech: "Action performed.", timestamp: timeStr, command: rawText)
    }

    public func executeInternetCall(recipient: String, isVideo: Bool = false, isWhatsApp: Bool = false, originalCommand: String = "", timeStr: String = "") async -> CommandResponse {
        var cleanTarget = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTarget.hasPrefix("to ") {
            cleanTarget = String(cleanTarget.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }

        let actualTime = timeStr.isEmpty ? DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium) : timeStr
        let actualCmd = originalCommand.isEmpty ? "call \(recipient)" : originalCommand

        if isWhatsApp {
            let digits = cleanTarget.filter { "0123456789+".contains($0) }
            if !digits.isEmpty, let url = URL(string: "https://wa.me/\(digits)") {
                NSWorkspace.shared.open(url)
                return CommandResponse(
                    success: true,
                    type: "communication",
                    app: "WhatsApp",
                    message: "Initiating WhatsApp Internet Call to \(cleanTarget)...",
                    speech: "Calling \(cleanTarget) on WhatsApp.",
                    timestamp: actualTime,
                    command: actualCmd
                )
            } else {
                _ = await openApp("whatsapp")
                return CommandResponse(
                    success: true,
                    type: "communication",
                    app: "WhatsApp",
                    message: "Opened WhatsApp for calling \(cleanTarget).",
                    speech: "Opening WhatsApp to call \(cleanTarget).",
                    timestamp: actualTime,
                    command: actualCmd
                )
            }
        }

        // FaceTime Internet Calling (Audio / Video)
        let scheme = isVideo ? "facetime" : "facetime-audio"
        let cleanAddress = cleanTarget.replacingOccurrences(of: " ", with: "")

        if cleanAddress.isEmpty {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            p.arguments = ["-a", "FaceTime"]
            try? p.run()
            return CommandResponse(
                success: true,
                type: "communication",
                app: "FaceTime",
                message: "Opening FaceTime for Internet Calling.",
                speech: "Opening FaceTime.",
                timestamp: actualTime,
                command: actualCmd
            )
        }

        if let encoded = cleanAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
           let callURL = URL(string: "\(scheme)://\(encoded)") {
            NSWorkspace.shared.open(callURL)
            let callType = isVideo ? "FaceTime Video" : "FaceTime Internet Audio"
            return CommandResponse(
                success: true,
                type: "communication",
                app: "FaceTime",
                message: "Initiating \(callType) call to \(cleanTarget)...",
                speech: "Calling \(cleanTarget).",
                timestamp: actualTime,
                command: actualCmd
            )
        }

        return CommandResponse(
            success: false,
            type: "communication",
            app: "FaceTime",
            message: "Unable to dial \(cleanTarget).",
            speech: "Unable to start call to \(cleanTarget).",
            timestamp: actualTime,
            command: actualCmd
        )
    }

    private func executeNativeOpen(target: String, originalCommand: String, timeStr: String) async -> CommandResponse {
        let lowerTarget = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowerTarget == "aura" || lowerTarget == "yourself" || lowerTarget == "assistant" || lowerTarget.isEmpty {
            Task { @MainActor in
                auraOpenWindow()
            }
            return CommandResponse(
                success: true,
                type: "aura_open",
                app: "AURA",
                message: "AURA opened and ready for your commands.",
                speech: "Opening AURA. I am ready.",
                timestamp: timeStr,
                command: originalCommand
            )
        }

        let resolvedApp = appAliases[target] ?? target

        // If target is WhatsApp or a website
        if target.contains("whatsapp") {
            // Check if WhatsApp desktop exists
            let wsApp = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "net.whatsapp.WhatsApp")
            if let wsApp = wsApp {
                _ = try? await NSWorkspace.shared.openApplication(at: wsApp, configuration: NSWorkspace.OpenConfiguration())
                self.lastOpenedTarget = "WhatsApp"
                return CommandResponse(success: true, type: "app_open", app: "WhatsApp", message: "Opened WhatsApp desktop application.", speech: "Opening WhatsApp", timestamp: timeStr, command: originalCommand)
            } else {
                // Open WhatsApp Web
                if let url = URL(string: "https://web.whatsapp.com") {
                    NSWorkspace.shared.open(url)
                    self.lastOpenedTarget = "whatsapp"
                    return CommandResponse(success: true, type: "app_open", app: "WhatsApp", message: "Launched WhatsApp Web in browser.", speech: "Opening WhatsApp", timestamp: timeStr, command: originalCommand)
                }
            }
        }

        // Check bookmarked websites
        if let site = websites.first(where: { $0.key == target || target.contains($0.key) }) {
            if let url = URL(string: site.url) {
                NSWorkspace.shared.open(url)
                self.lastOpenedTarget = site.key
                return CommandResponse(success: true, type: "website_open", app: site.title, message: "Opened \(site.title) in browser.", speech: "Opening \(site.title)", timestamp: timeStr, command: originalCommand)
            }
        }

        // Open native application
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-a", resolvedApp]
        do {
            try p.run()
            p.waitUntilExit()
            if p.terminationStatus == 0 {
                self.lastOpenedTarget = resolvedApp
                return CommandResponse(success: true, type: "app_open", app: resolvedApp, message: "Successfully opened \(resolvedApp).", speech: "Opening \(resolvedApp)", timestamp: timeStr, command: originalCommand)
            }
        } catch {}

        return CommandResponse(success: false, type: "app_open", app: resolvedApp, message: "Could not open \(resolvedApp).", speech: "Unable to open \(resolvedApp)", timestamp: timeStr, command: originalCommand)
    }

    private func executeNativeClose(target: String, originalCommand: String, timeStr: String) async -> CommandResponse {
        var cleanTarget = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let leadFillers = ["the ", "all ", "my ", "this ", "that "]
        var changed = true
        while changed {
            changed = false
            for f in leadFillers {
                if cleanTarget.starts(with: f) {
                    cleanTarget = String(cleanTarget.dropFirst(f.count)).trimmingCharacters(in: .whitespaces)
                    changed = true
                    break
                }
            }
        }

        let tailFillers = [" app", " apps", " application", " applications", " window", " windows", " program"]
        changed = true
        while changed {
            changed = false
            for f in tailFillers {
                if cleanTarget.hasSuffix(f) {
                    cleanTarget = String(cleanTarget.dropLast(f.count)).trimmingCharacters(in: .whitespaces)
                    changed = true
                    break
                }
            }
        }

        // If target is AURA itself
        if cleanTarget == "aura" || cleanTarget == "yourself" || cleanTarget == "assistant" || cleanTarget == "shut down" || cleanTarget == "shutdown" {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                auraCloseWindow()
            }
            return CommandResponse(
                success: true,
                type: "aura_close",
                app: "AURA",
                message: "AURA closed into background standby. Say \"open\" or \"wake up\" anytime to bring me back.",
                speech: "Closing AURA. Say open anytime to wake me up.",
                timestamp: timeStr,
                command: originalCommand
            )
        }

        // Generic close: "close", "close application", "close applications", "close app", "close apps", "close this", "close it", "close active", "close current", "close window"
        let isGeneric = cleanTarget.isEmpty ||
                        cleanTarget == "application" ||
                        cleanTarget == "applications" ||
                        cleanTarget == "app" ||
                        cleanTarget == "apps" ||
                        cleanTarget == "this" ||
                        cleanTarget == "it" ||
                        cleanTarget == "active" ||
                        cleanTarget == "current" ||
                        cleanTarget == "window" ||
                        cleanTarget == "program"

        if isGeneric {
            // A. If an app was previously opened via AURA in this session (e.g. Calculator, WhatsApp), close it!
            if !lastOpenedTarget.isEmpty {
                let prevTarget = lastOpenedTarget
                self.lastOpenedTarget = ""
                return await executeNativeClose(target: prevTarget, originalCommand: originalCommand, timeStr: timeStr)
            }

            // B. If user requested closing multiple applications ("close applications" / "close apps")
            if cleanTarget == "applications" || cleanTarget == "apps" {
                var closedList: [String] = []
                for runningApp in NSWorkspace.shared.runningApplications {
                    guard runningApp.activationPolicy == .regular,
                          runningApp.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                          runningApp.bundleIdentifier != Bundle.main.bundleIdentifier,
                          runningApp.localizedName != "AURA",
                          runningApp.localizedName != "Finder" else { continue }

                    let name = runningApp.localizedName ?? "App"
                    runningApp.terminate()
                    runningApp.forceTerminate()
                    closedList.append(name)
                }
                if !closedList.isEmpty {
                    let display = closedList.prefix(3).joined(separator: ", ")
                    return CommandResponse(
                        success: true,
                        type: "app_close",
                        app: "Applications",
                        message: "Closed running applications (\(display)).",
                        speech: "Closed running applications.",
                        timestamp: timeStr,
                        command: originalCommand
                    )
                }
            }

            // C. Terminate frontmost non-AURA application
            if let front = NSWorkspace.shared.frontmostApplication,
               front.processIdentifier != ProcessInfo.processInfo.processIdentifier,
               front.bundleIdentifier != Bundle.main.bundleIdentifier,
               front.localizedName != "AURA",
               front.localizedName != "Finder" {
                let name = front.localizedName ?? "Application"
                front.terminate()
                front.forceTerminate()
                runAppleScript("tell application \"\(name)\" to quit")
                return CommandResponse(
                    success: true,
                    type: "app_close",
                    app: name,
                    message: "Closed \(name).",
                    speech: "Closed \(name)",
                    timestamp: timeStr,
                    command: originalCommand
                )
            }

            // D. Terminate any active regular user app
            for runningApp in NSWorkspace.shared.runningApplications {
                if runningApp.activationPolicy == .regular,
                   runningApp.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                   runningApp.bundleIdentifier != Bundle.main.bundleIdentifier,
                   runningApp.localizedName != "AURA",
                   runningApp.localizedName != "Finder" {
                    let name = runningApp.localizedName ?? "Application"
                    runningApp.terminate()
                    runningApp.forceTerminate()
                    return CommandResponse(
                        success: true,
                        type: "app_close",
                        app: name,
                        message: "Closed \(name).",
                        speech: "Closed \(name)",
                        timestamp: timeStr,
                        command: originalCommand
                    )
                }
            }

            // E. Fallback: Close active window via Command+W
            let script = "tell application \"System Events\" to keystroke \"w\" using command down"
            runAppleScript(script)
            return CommandResponse(
                success: true,
                type: "app_close",
                app: "Window",
                message: "Closed active window.",
                speech: "Closed active window.",
                timestamp: timeStr,
                command: originalCommand
            )
        }

        var resolved = appAliases[cleanTarget] ?? cleanTarget.capitalized
        if let match = apps.first(where: {
            $0.key.lowercased() == cleanTarget ||
            $0.name.lowercased() == cleanTarget ||
            $0.key.lowercased().contains(cleanTarget) ||
            cleanTarget.contains($0.key.lowercased())
        }) {
            resolved = match.name
        }

        // 1. Terminate matching native applications via NSWorkspace (Graceful + Force Terminate)
        for runningApp in NSWorkspace.shared.runningApplications {
            guard runningApp.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                  runningApp.bundleIdentifier != Bundle.main.bundleIdentifier,
                  runningApp.localizedName != "AURA" else {
                continue
            }
            if let name = runningApp.localizedName {
                if name.localizedCaseInsensitiveContains(resolved) ||
                   resolved.localizedCaseInsensitiveContains(name) ||
                   name.localizedCaseInsensitiveContains(cleanTarget) ||
                   cleanTarget.localizedCaseInsensitiveContains(name) ||
                   (runningApp.bundleIdentifier?.localizedCaseInsensitiveContains(cleanTarget) == true) ||
                   (runningApp.bundleIdentifier?.localizedCaseInsensitiveContains(resolved) == true) {
                    runningApp.terminate()
                    runningApp.forceTerminate()
                }
            }
        }

        // 2. Close browser tabs for WhatsApp or web services
        let webServices = ["whatsapp", "chatgpt", "youtube", "google", "github", "reddit", "twitter", "notion", "figma"]
        for service in webServices {
            if cleanTarget.contains(service) {
                let term = service == "twitter" ? "x.com" : service
                let closeTabScript = """
                tell application "System Events"
                    set isRunningChrome to (count (every process whose name is "Google Chrome")) > 0
                    set isRunningBrave to (count (every process whose name is "Brave Browser")) > 0
                    set isRunningSafari to (count (every process whose name is "Safari")) > 0
                end tell
                if isRunningChrome then
                    tell application "Google Chrome"
                        repeat with w in windows
                            set tabIdx to 1
                            repeat while tabIdx <= (count of tabs of w)
                                set t to tab tabIdx of w
                                if (URL of t contains "\(term)") or (title of t contains "\(term)") then
                                    close t
                                else
                                    set tabIdx to tabIdx + 1
                                end if
                            end repeat
                        end repeat
                    end tell
                end if
                if isRunningBrave then
                    tell application "Brave Browser"
                        repeat with w in windows
                            set tabIdx to 1
                            repeat while tabIdx <= (count of tabs of w)
                                set t to tab tabIdx of w
                                if (URL of t contains "\(term)") or (title of t contains "\(term)") then
                                    close t
                                else
                                    set tabIdx to tabIdx + 1
                                end if
                            end repeat
                        end repeat
                    end tell
                end if
                if isRunningSafari then
                    tell application "Safari"
                        repeat with w in windows
                            set tabIdx to 1
                            repeat while tabIdx <= (count of tabs of w)
                                set t to tab tabIdx of w
                                if (URL of t contains "\(term)") or (name of t contains "\(term)") then
                                    close t
                                else
                                    set tabIdx to tabIdx + 1
                                end if
                            end repeat
                        end repeat
                    end tell
                end if
                """
                runAppleScript(closeTabScript)
            }
        }

        // 3. AppleScript graceful quit
        let quitScript = "tell application \"\(resolved)\" to quit"
        runAppleScript(quitScript)
        if resolved.lowercased() != cleanTarget {
            runAppleScript("tell application \"\(cleanTarget)\" to quit")
        }

        // 4. Fallback killall & pkill for immediate termination
        let pKill = Process()
        pKill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pKill.arguments = ["-if", resolved]
        try? pKill.run()
        pKill.waitUntilExit()

        let pKill2 = Process()
        pKill2.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pKill2.arguments = ["-if", cleanTarget]
        try? pKill2.run()
        pKill2.waitUntilExit()

        let pKill3 = Process()
        pKill3.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        pKill3.arguments = [resolved]
        try? pKill3.run()
        pKill3.waitUntilExit()

        if lastOpenedTarget.lowercased() == cleanTarget || lastOpenedTarget.lowercased() == resolved.lowercased() {
            lastOpenedTarget = ""
        }

        return CommandResponse(
            success: true,
            type: "app_close",
            app: resolved,
            message: "Closed \(resolved).",
            speech: "Closed \(resolved)",
            timestamp: timeStr,
            command: originalCommand
        )
    }

    private func runAppleScript(_ script: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        try? p.run()
        p.waitUntilExit()
    }

    // MARK: - Direct Helpers
    public func openApp(_ key: String) async {
        let matched = apps.first(where: { $0.key == key })?.name ?? key
        _ = await executeCommand("open \(matched)")
    }

    public func closeApp(_ key: String) async {
        let matched = apps.first(where: { $0.key == key })?.name ?? key
        _ = await executeCommand("close \(matched)")
    }

    public func openWebsite(_ key: String) async {
        if let site = websites.first(where: { $0.key == key }) {
            _ = await executeCommand("open \(site.title)")
        }
    }

    public func captureScreenshot() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = home.appendingPathComponent("Desktop")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "Screenshot_\(formatter.string(from: Date())).png"
        let fileURL = desktop.appendingPathComponent(filename)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-x", fileURL.path]

        do {
            try task.run()
            task.waitUntilExit()
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let entry = HistoryEntry(
                command: "screenshot",
                message: "Screenshot saved to Desktop: \(filename)",
                speech: "Screenshot captured and saved to Desktop.",
                timestamp: timeStr,
                success: true
            )
            self.history.insert(entry, at: 0)
            self.statusMessage = "Screenshot saved: \(filename)"
        } catch {
            self.statusMessage = "Screenshot failed: \(error)"
        }
    }
}
