import Foundation

// MARK: - Tasks

/// One task: its row in the sidebar and its page. Map Katana's own task data onto this.
public struct TaskPage: Identifiable, Sendable {
    public var id: UUID
    public var title: String
    /// Second line in the sidebar, e.g. "On investigate-katana-voice".
    public var summary: String?
    public var status: TaskStatus
    /// When the current status started. Drives "Finished · 4m ago".
    public var statusSince: Date
    /// Used in the composer placeholder: "Write to Claude…".
    public var agentName: String
    /// Right side of the status row, e.g. "Opus 5.5 · high effort · claude1".
    public var modelLabel: String
    /// Shows the globe tab in the header.
    public var hasBrowser: Bool
    public var messages: [TranscriptMessage]
    /// Under the transcript, e.g. "1 commit · 3 files · +59 −17".
    public var changeSummary: String?
    /// Under the change summary, e.g. "Merge into main", "Pull request", "Mark done".
    public var buttons: [TaskButton]

    public init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        status: TaskStatus,
        statusSince: Date = .now,
        agentName: String,
        modelLabel: String,
        hasBrowser: Bool = false,
        messages: [TranscriptMessage],
        changeSummary: String? = nil,
        buttons: [TaskButton] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.status = status
        self.statusSince = statusSince
        self.agentName = agentName
        self.modelLabel = modelLabel
        self.hasBrowser = hasBrowser
        self.messages = messages
        self.changeSummary = changeSummary
        self.buttons = buttons
    }
}

public enum TaskStatus: String, CaseIterable, Sendable {
    /// `review`: the agent is done and its result waits for your call ("Your move",
    /// usually a merge). It counts as needing you; `finished` needs nothing more.
    case working, needsYou, review, finished, failed

    public var label: String {
        switch self {
        case .working: "Working"
        case .needsYou: "Needs you"
        case .review: "Ready for review"
        case .finished: "Finished"
        case .failed: "Failed"
        }
    }

    /// Working, needs-you and ready-for-review tasks are listed first in the sidebar.
    public var isActive: Bool { self == .working || needsUser }

    /// Waiting on the user: blocked on a question, or done and ready for review.
    public var needsUser: Bool { self == .needsYou || self == .review }
}

public struct TaskButton: Identifiable, Hashable, Sendable {
    /// `primary` is the one filled button for the main next step; `link` is a
    /// quieter raised button beside it; `finish` ends the task ("Mark done") and
    /// sits apart at the row's far end, so it doesn't read as a delivery action.
    public enum Style: Hashable, Sendable { case primary, link, finish }

    public var id: String
    public var title: String
    /// Shown after the title, e.g. "⌘↩".
    public var shortcutHint: String?
    public var style: Style

    public init(id: String, title: String, shortcutHint: String? = nil, style: Style = .link) {
        self.id = id
        self.title = title
        self.shortcutHint = shortcutHint
        self.style = style
    }
}

/// The views in a task page's header: its page, its browser and its terminal.
public enum TaskPageTab: String, CaseIterable, Sendable {
    case page, browser, terminal
}

public struct TranscriptMessage: Identifiable, Hashable, Sendable {
    public enum Role: Hashable, Sendable { case agent, user }

    public var id: UUID
    public var role: Role
    /// The agent's closing summary. It gets a little more space above it.
    public var isReport: Bool
    public var blocks: [TranscriptBlock]

    public init(id: UUID = UUID(), role: Role = .agent, isReport: Bool = false, blocks: [TranscriptBlock]) {
        self.id = id
        self.role = role
        self.isReport = isReport
        self.blocks = blocks
    }

    public static func agent(_ markdown: String) -> TranscriptMessage {
        TranscriptMessage(blocks: [.paragraph(markdown)])
    }

    public static func user(_ markdown: String) -> TranscriptMessage {
        TranscriptMessage(role: .user, blocks: [.paragraph(markdown)])
    }
}

/// Text is inline Markdown: `**bold**`, `*italic*`, `` `code` `` and `[links](url)`.
public enum TranscriptBlock: Hashable, Sendable {
    case paragraph(String)
    case bullets([String])
    /// Label and value rows: "You asked", "Where it is", "Your move".
    case facts([TaskFact])
}

public struct TaskFact: Hashable, Sendable {
    public var label: String
    public var value: String
    /// Dimmed after the value, e.g. "5m ago".
    public var detail: String?

    public init(_ label: String, _ value: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
    }
}

// MARK: - Katana

/// Katana's own conversation in the middle pane.
public struct KatanaConversation: Sendable {
    public var messages: [KatanaMessage]
    public var isListening: Bool
    /// Katana is working on a reply. Shows a small dash under the last message.
    public var isThinking: Bool
    /// Katana's reply is being spoken. Independent of microphone listening.
    public var isSpeaking: Bool
    /// Above the composer, e.g. "GPT-6.1-Terra · low effort · max.blade.hansen account".
    public var modelLabel: String

    public init(messages: [KatanaMessage], isListening: Bool = false, isThinking: Bool = false, isSpeaking: Bool = false, modelLabel: String) {
        self.messages = messages
        self.isListening = isListening
        self.isThinking = isThinking
        self.isSpeaking = isSpeaking
        self.modelLabel = modelLabel
    }
}

public struct KatanaMessage: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// Katana speaking. Inline Markdown.
        case katana(String)
        /// The user. `notes` are the bracketed context lines in the same bubble,
        /// e.g. "Beside you: Fast and safe voice hang-up, a task's page."
        case user(String, notes: [String])
        /// A small status line, e.g. "“Wake word on livestream” finished". With a
        /// `taskID`, the line gets a "Review" (or "Open") button for that task.
        case event(String, status: TaskStatus, taskID: UUID? = nil)
    }

    public var id: UUID
    public var kind: Kind

    public init(id: UUID = UUID(), _ kind: Kind) {
        self.id = id
        self.kind = kind
    }
}

// MARK: - Sidebar

/// What the middle pane shows: Katana, or a task you went to.
public enum WorkspaceSelection: Hashable, Sendable {
    case katana
    case task(UUID)
}

/// The bottom of the sidebar.
public struct WorkspaceFooter: Sendable {
    /// Dev builds only, e.g. "main @ 633e0c95 · Preserve macOS paste".
    public var devBuildLine: String?
    /// Share of the week's usage spent, 0...1.
    public var usage: Double
    /// E.g. "wk 24% used".
    public var usageLabel: String

    public init(devBuildLine: String? = nil, usage: Double, usageLabel: String) {
        self.devBuildLine = devBuildLine
        self.usage = usage
        self.usageLabel = usageLabel
    }
}
