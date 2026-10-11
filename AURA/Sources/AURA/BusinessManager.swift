import Foundation
import AppKit
import SwiftUI

@MainActor
public final class BusinessManager: ObservableObject {
    public static let shared = BusinessManager()

    // MARK: - Published State
    @Published public var tasks: [BusinessTask] = []
    @Published public var currentDraft: ExecutiveEmailDraft? = nil
    @Published public var currentAgenda: MeetingAgenda? = nil
    @Published public var dailyBrief: DailyExecutiveBrief? = nil
    @Published public var isGenerating: Bool = false
    @Published public var statusNotice: String = ""

    // Enterprise Application Registry
    public let enterpriseApps: [AppItem] = [
        AppItem(key: "slack", name: "Slack", category: "Enterprise Comms", icon: "bubble.left.and.bubble.right.fill", isInstalled: true),
        AppItem(key: "teams", name: "Microsoft Teams", category: "Enterprise Comms", icon: "person.3.sequence.fill", isInstalled: true),
        AppItem(key: "zoom", name: "Zoom", category: "Conferencing", icon: "video.fill", isInstalled: true),
        AppItem(key: "notion", name: "Notion", category: "Knowledge & Docs", icon: "doc.richtext.fill", isInstalled: true),
        AppItem(key: "linear", name: "Linear", category: "Issue Tracking", icon: "arrow.triangle.pull", isInstalled: true),
        AppItem(key: "jira", name: "Jira", category: "Agile Project Mgmt", icon: "checklist", isInstalled: true),
        AppItem(key: "excel", name: "Microsoft Excel", category: "Financial Modeling", icon: "tablecells.fill", isInstalled: true),
        AppItem(key: "sheets", name: "Google Sheets", category: "Spreadsheets", icon: "tablecells", isInstalled: true),
        AppItem(key: "powerpoint", name: "Microsoft PowerPoint", category: "Executive Decks", icon: "rectangle.inset.filled.and.person.filled", isInstalled: true),
        AppItem(key: "word", name: "Microsoft Word", category: "Contracts & Docs", icon: "doc.text.fill", isInstalled: true),
        AppItem(key: "github", name: "GitHub Desktop", category: "Version Control", icon: "chevron.left.forwardslash.chevron.right", isInstalled: true),
        AppItem(key: "mail", name: "Mail", category: "Executive Inbox", icon: "envelope.fill", isInstalled: true),
        AppItem(key: "calendar", name: "Calendar", category: "Schedule", icon: "calendar", isInstalled: true),
        AppItem(key: "notes", name: "Notes", category: "Meeting Minutes", icon: "note.text", isInstalled: true),
        AppItem(key: "terminal", name: "Terminal", category: "DevOps & Cloud", icon: "terminal.fill", isInstalled: true),
        AppItem(key: "vscode", name: "Visual Studio Code", category: "Engineering", icon: "chevron.left.forwardslash.chevron.right", isInstalled: true)
    ]

    public let enterpriseWebsites: [WebsiteItem] = [
        WebsiteItem(key: "notion", title: "Notion Workspace", url: "https://notion.so", category: "Productivity", badge: "Docs", icon: "doc.text.image.fill"),
        WebsiteItem(key: "linear", title: "Linear App", url: "https://linear.app", category: "Engineering", badge: "Sprints", icon: "target"),
        WebsiteItem(key: "jira", title: "Atlassian Jira", url: "https://atlassian.net", category: "Agile", badge: "Projects", icon: "checklist"),
        WebsiteItem(key: "figma", title: "Figma Executive", url: "https://figma.com", category: "Design", badge: "Specs", icon: "paintpalette.fill"),
        WebsiteItem(key: "github", title: "GitHub Enterprise", url: "https://github.com", category: "Code", badge: "Repos", icon: "chevron.left.forwardslash.chevron.right"),
        WebsiteItem(key: "sheets", title: "Google Sheets", url: "https://sheets.google.com", category: "Finance", badge: "Models", icon: "tablecells"),
        WebsiteItem(key: "docs", title: "Google Docs", url: "https://docs.google.com", category: "Docs", badge: "Briefs", icon: "doc.plaintext"),
        WebsiteItem(key: "stripe", title: "Stripe Billing", url: "https://dashboard.stripe.com", category: "Finance", badge: "Revenue", icon: "creditcard.fill"),
        WebsiteItem(key: "linkedin", title: "LinkedIn Sales Nav", url: "https://linkedin.com", category: "Sales", badge: "B2B Leads", icon: "person.crop.rectangle.fill"),
        WebsiteItem(key: "hubspot", title: "HubSpot CRM", url: "https://app.hubspot.com", category: "CRM", badge: "Pipeline", icon: "chart.line.uptrend.xyaxis")
    ]

    private let storageURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let auraDir = appSupport.appendingPathComponent("AURA")
        try? FileManager.default.createDirectory(at: auraDir, withIntermediateDirectories: true)
        self.storageURL = auraDir.appendingPathComponent("business_tasks.json")
        loadTasks()
        if tasks.isEmpty {
            seedDefaultTasks()
        }
        self.dailyBrief = generateExecutiveBrief()
    }

    // MARK: - Task Management & Persistence
    public func loadTasks() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let loaded = try JSONDecoder().decode([BusinessTask].self, from: data)
            self.tasks = loaded
        } catch {
            print("Failed to load business tasks: \(error)")
        }
    }

    public func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save business tasks: \(error)")
        }
    }

    public func addTask(title: String, priority: BusinessPriority = .p1, category: String = "Strategy", dueDate: String = "Today") {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTask = BusinessTask(
            title: trimmed,
            priority: priority,
            category: category,
            isCompleted: false,
            dueDate: dueDate
        )
        tasks.insert(newTask, at: 0)
        saveTasks()
        statusNotice = "Added priority deliverable: \(trimmed)"
        dailyBrief = generateExecutiveBrief()
    }

    public func toggleTask(id: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].isCompleted.toggle()
            saveTasks()
            dailyBrief = generateExecutiveBrief()
        }
    }

    public func deleteTask(id: UUID) {
        tasks.removeAll(where: { $0.id == id })
        saveTasks()
        dailyBrief = generateExecutiveBrief()
    }

    public func clearCompleted() {
        tasks.removeAll(where: { $0.isCompleted })
        saveTasks()
        dailyBrief = generateExecutiveBrief()
    }

    private func seedDefaultTasks() {
        tasks = [
            BusinessTask(title: "Review Q4 Executive Strategy & Financial Budget", priority: .p0, category: "Strategy", dueDate: "Today"),
            BusinessTask(title: "Finalize Client Enterprise Proposal & SLA Terms", priority: .p0, category: "Sales", dueDate: "Today 3:00 PM"),
            BusinessTask(title: "Sprint Review & Engineering Roadmap Alignment", priority: .p1, category: "Product", dueDate: "Tomorrow"),
            BusinessTask(title: "Analyze Monthly Burn Rate & Cash Runway Projections", priority: .p1, category: "Finance", dueDate: "This Week"),
            BusinessTask(title: "Conduct 1-on-1 Performance & Leadership Sync", priority: .p2, category: "Leadership", dueDate: "Thursday")
        ]
        saveTasks()
    }

    // MARK: - Executive Daily Briefing
    public func generateExecutiveBrief() -> DailyExecutiveBrief {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        let dateStr = formatter.string(from: Date())

        let hour = Calendar.current.component(.hour, from: Date())
        let greetingPrefix: String
        if hour < 12 {
            greetingPrefix = "Good morning"
        } else if hour < 17 {
            greetingPrefix = "Good afternoon"
        } else {
            greetingPrefix = "Good evening"
        }

        let pendingP0 = tasks.filter { !$0.isCompleted && $0.priority == .p0 }.count
        let pendingTotal = tasks.filter { !$0.isCompleted }.count

        let topDeliverables = tasks
            .filter { !$0.isCompleted }
            .prefix(3)
            .map { "• [\($0.priority.shortLabel)] \($0.title)" }

        let quotes = [
            "\"Strategy without tactics is the slowest route to victory. Tactics without strategy is the noise before defeat.\"",
            "\"Focus is a decision on what NOT to do. Protect the team's critical path.\"",
            "\"Speed in decision-making creates velocity in execution.\"",
            "\"High agency leaders convert ambiguity into structured outcomes.\"",
            "\"Measure what moves the needle; delegate the operational noise.\""
        ]
        let quote = quotes[abs(dateStr.hashValue) % quotes.count]

        let speechText = "\(greetingPrefix). Here is your executive briefing for \(dateStr). You currently have \(pendingP0) critical P0 deliverables and \(pendingTotal) active corporate tasks. Top focus is \(tasks.first(where: { !$0.isCompleted })?.title ?? "staying ahead of roadmap")."

        return DailyExecutiveBrief(
            dateString: dateStr,
            greeting: "\(greetingPrefix), Executive",
            focusQuote: quote,
            pendingP0Count: pendingP0,
            pendingTotalCount: pendingTotal,
            strategicDeliverables: Array(topDeliverables),
            marketSentiment: "Macro Outlook: Resilient • Tech Velocity: High",
            speechBrief: speechText
        )
    }

    // MARK: - Executive Email Composer
    public func draftEmail(
        recipient: String,
        subject: String,
        contextPoints: String,
        tone: EmailTone
    ) -> ExecutiveEmailDraft {
        let cleanRecipient = recipient.isEmpty ? "Team / Partner" : recipient
        let cleanSubject = subject.isEmpty ? "Executive Strategy Update" : subject
        let cleanPoints = contextPoints.isEmpty ? "Review recent milestones and align on next steps." : contextPoints

        let greeting = "Dear \(cleanRecipient),"
        var bodyContent = ""

        switch tone {
        case .executiveDirect:
            bodyContent = """
            \(greeting)

            I am writing to share key decisions regarding \(cleanSubject).

            Core Priorities:
            \(formatBulletPoints(cleanPoints))

            Next Steps & Action Gates:
            • Please confirm ownership of deliverables by end of day.
            • We remain on track against our quarterly milestone goals.

            Best regards,
            Executive Office
            """

        case .clientProposal:
            bodyContent = """
            \(greeting)

            Thank you for our productive discussions regarding our enterprise collaboration.

            In line with your strategic goals, our proposal addresses your core requirements:
            \(formatBulletPoints(cleanPoints))

            Key Value Proposition:
            • Accelerated time-to-market with enterprise-grade SLA compliance.
            • Dedicated advisory support and seamless systems integration.

            We are eager to finalize terms. I welcome a 15-minute alignment call this week to execute the agreement.

            Sincerely,
            Executive Leadership
            """

        case .gentleFollowUp:
            bodyContent = """
            \(greeting)

            Following up on our recent communication regarding \(cleanSubject).

            Quick status check on the following items:
            \(formatBulletPoints(cleanPoints))

            Could you provide an update on current progress or any blockers we can help unblock? Appreciate your guidance.

            Warm regards,
            Executive Office
            """

        case .projectEscalation:
            bodyContent = """
            \(greeting)

            This is an executive escalation concerning critical deliverables for \(cleanSubject).

            Identified Blockers & Urgency:
            \(formatBulletPoints(cleanPoints))

            Required Immediate Action:
            • Convene emergency 20-minute alignment session today.
            • Reallocate necessary engineering/operational bandwidth to resolve bottleneck.

            We need full resolution within 24 hours to preserve SLA commitments.

            Respectfully,
            Executive Operations
            """

        case .meetingInvite:
            bodyContent = """
            \(greeting)

            I would like to convene an executive working session on \(cleanSubject).

            Proposed Agenda & Objectives:
            \(formatBulletPoints(cleanPoints))

            Please confirm if your calendar accommodates a 30-minute sync tomorrow afternoon, or let me know a preferred window.

            Best regards,
            Executive Office
            """
        }

        let draft = ExecutiveEmailDraft(
            recipient: cleanRecipient,
            subject: cleanSubject,
            body: bodyContent,
            tone: tone
        )
        self.currentDraft = draft
        self.statusNotice = "Generated \(tone.rawValue) email draft."
        return draft
    }

    private func formatBulletPoints(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if lines.isEmpty {
            return "• " + text
        }
        return lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("•") || trimmed.hasPrefix("-") ? trimmed : "• \(trimmed)"
        }.joined(separator: "\n")
    }

    public func copyDraftToClipboard() {
        guard let draft = currentDraft else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(draft.body, forType: .string)
        statusNotice = "Email draft copied to clipboard!"
    }

    public func openDraftInMail() {
        guard let draft = currentDraft else { return }
        let subjectEncoded = draft.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = draft.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let recipientEncoded = draft.recipient.contains("@") ? draft.recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "" : ""

        if let mailURL = URL(string: "mailto:\(recipientEncoded)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            NSWorkspace.shared.open(mailURL)
            statusNotice = "Opened pre-filled draft in Mail."
        }
    }

    // MARK: - Meeting & Agenda Architect
    public func generateMeetingAgenda(title: String, duration: Int, goal: String) -> MeetingAgenda {
        let cleanTitle = title.isEmpty ? "Executive Strategy Alignment" : title
        let cleanGoal = goal.isEmpty ? "Align on Q4 Roadmap, resource allocation, and key OKRs." : goal

        var topics: [String] = []
        var outcomes: [String] = []

        if duration <= 15 {
            topics = [
                "00-03m: Standup Pulse & Critical Blockers",
                "03-10m: Daily Sprint Velocity & Deliverables Check",
                "10-15m: Next Steps & Immediate Ownership"
            ]
            outcomes = [
                "All blockers identified with direct assignees",
                "Day's sprint targets locked in"
            ]
        } else if duration <= 30 {
            topics = [
                "00-05m: Executive Summary & Context Setting",
                "05-18m: Deep-Dive on Core Proposals & Tradeoffs",
                "18-25m: Risk Mitigation, Budget, & Timeline Scenarios",
                "25-30m: Decision Lock & Immediate Next Actions"
            ]
            outcomes = [
                "Clear Go/No-Go decision on primary topic",
                "Assigned DRI (Directly Responsible Individual) for each workstream"
            ]
        } else {
            topics = [
                "00-10m: Strategic Context, Financial KPIs & Metric Review",
                "10-30m: Architectural & Strategic Options Evaluation",
                "30-45m: Cross-Functional Alignment (Ops, Sales, Product)",
                "45-55m: Risk Assessment & Governance Controls",
                "55-60m: Summary of Decisions, Approvals, & Timelines"
            ]
            outcomes = [
                "Executive Consensus & Signed Approval Path",
                "Documented Action Matrix with 14-day Checkpoints"
            ]
        }

        let agenda = MeetingAgenda(
            title: cleanTitle,
            durationMinutes: duration,
            objective: cleanGoal,
            topics: topics,
            expectedOutcomes: outcomes
        )
        self.currentAgenda = agenda
        self.statusNotice = "Generated \(duration)-minute agenda for: \(cleanTitle)"
        return agenda
    }

    public func exportAgendaToNotes() {
        guard let agenda = currentAgenda else { return }
        let script = """
        tell application "Notes"
            activate
            tell account "DefaultAccount"
                make new note at folder "Notes" with properties {name:"Agenda: \(agenda.title)", body:"<h1>Agenda: \(agenda.title) (\(agenda.durationMinutes) min)</h1><p><b>Objective:</b> \(agenda.objective)</p><h3>Topics:</h3><ul>\(agenda.topics.map { "<li>" + $0 + "</li>" }.joined())</ul><h3>Expected Outcomes:</h3><ul>\(agenda.expectedOutcomes.map { "<li>" + $0 + "</li>" }.joined())</ul>"}
            end tell
        end tell
        """
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        try? p.run()
        statusNotice = "Exported agenda to Apple Notes."
    }

    // MARK: - Financial KPI & Health Engine
    public func calculateRunway(cashBalance: Double, monthlyBurn: Double) -> (months: Double, status: String, colorHex: String) {
        guard monthlyBurn > 0 else {
            return (99.0, "Infinite / Cashflow Positive", "#10B981")
        }
        let months = cashBalance / monthlyBurn
        if months >= 24 {
            return (months, "Exceptional Runway (>24m)", "#10B981")
        } else if months >= 12 {
            return (months, "Healthy Runway (12-24m)", "#3B82F6")
        } else if months >= 6 {
            return (months, "Fundraising Recommended (6-12m)", "#F59E0B")
        } else {
            return (months, "Critical Runway (<6m) - Immediate Action Required", "#EF4444")
        }
    }

    public func calculateLtvCac(ltv: Double, cac: Double) -> (ratio: Double, status: String, colorHex: String) {
        guard cac > 0 else {
            return (0.0, "Invalid CAC", "#EF4444")
        }
        let ratio = ltv / cac
        if ratio >= 4.0 {
            return (ratio, "World-Class Unit Economics (>=4x)", "#10B981")
        } else if ratio >= 3.0 {
            return (ratio, "Healthy SaaS Standard (3x)", "#3B82F6")
        } else if ratio >= 1.5 {
            return (ratio, "Moderate Efficiency (1.5x - 3x)", "#F59E0B")
        } else {
            return (ratio, "Sub-optimal Acquisition Cost (<1.5x)", "#EF4444")
        }
    }

    public func calculateMrrGrowth(currentMrr: Double, prevMrr: Double) -> (growthRate: Double, arr: Double) {
        let arr = currentMrr * 12.0
        guard prevMrr > 0 else { return (0.0, arr) }
        let growth = ((currentMrr - prevMrr) / prevMrr) * 100.0
        return (growth, arr)
    }

    public func calculateRoi(revenue: Double, cost: Double) -> (roiPercent: Double, netProfit: Double) {
        let netProfit = revenue - cost
        guard cost > 0 else { return (0.0, netProfit) }
        let roi = (netProfit / cost) * 100.0
        return (roi, netProfit)
    }
}
