import SwiftUI

/// What the task page asks the app to do. All of them default to doing nothing.
public struct TaskPageActions {
    /// The user sent a message from the composer.
    public var send: (String) -> Void
    /// The mic button was turned on (`true`) or off (`false`).
    public var micToggle: (Bool) -> Void
    /// "Go to it" in the header.
    public var goToIt: () -> Void
    /// The close button in the header.
    public var close: () -> Void
    /// One of the page's `TaskButton`s, by id.
    public var button: (String) -> Void
    /// An effort picked from the model menu in the composer. Without it, the
    /// model shows as a plain label.
    public var setEffort: ((String) -> Void)?

    public init(
        send: @escaping (String) -> Void = { _ in },
        micToggle: @escaping (Bool) -> Void = { _ in },
        goToIt: @escaping () -> Void = {},
        close: @escaping () -> Void = {},
        button: @escaping (String) -> Void = { _ in },
        setEffort: ((String) -> Void)? = nil
    ) {
        self.send = send
        self.micToggle = micToggle
        self.goToIt = goToIt
        self.close = close
        self.button = button
        self.setEffort = setEffort
    }
}

/// A task's page: beside Katana, in the middle when you go to it, or in a window of its own.
///
/// It only draws. The app owns the `TaskPage` and updates it; the view reports
/// what the user did through `TaskPageActions`. Pass Katana's real browser and
/// terminal views for the other two tabs.
public struct TaskPageView<Browser: View, Terminal: View>: View {
    private let page: TaskPage
    private let showsGoToIt: Bool
    private let actions: TaskPageActions
    private let browser: Browser
    private let terminal: Terminal
    @State private var tab: TaskPageTab
    @State private var listening = false
    private static var endID: String { "task-page-end" }

    public init(
        page: TaskPage,
        initialTab: TaskPageTab = .page,
        showsGoToIt: Bool = true,
        actions: TaskPageActions = TaskPageActions(),
        @ViewBuilder browser: () -> Browser,
        @ViewBuilder terminal: () -> Terminal
    ) {
        self.page = page
        self.showsGoToIt = showsGoToIt
        self.actions = actions
        self.browser = browser()
        self.terminal = terminal()
        _tab = State(initialValue: initialTab)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                switch tab {
                case .page: pageContent
                case .browser: browser
                case .terminal: terminal
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: page.hasBrowser) { _, hasBrowser in
            if !hasBrowser, tab == .browser { tab = .page }
        }
    }

    private var tabs: [TaskPageTab] {
        page.hasBrowser ? [.page, .browser, .terminal] : [.page, .terminal]
    }

    private var header: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title)
                    .font(KatanaTheme.titleFont)
                    .foregroundStyle(KatanaTheme.textTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
                TaskStatusRow(status: page.status, since: page.statusSince, compact: true)
            }

            Spacer(minLength: 16)

            PaneTabs(tabs: tabs, selection: tab, icon: \.icon) { tab = $0 }

            if showsGoToIt {
                HeaderIconButton(systemImage: "arrow.up.left.and.arrow.down.right", label: "Go to it: show this task in the middle", action: actions.goToIt)
                    .padding(.leading, 10)
            }

            CloseButton(action: actions.close)
                .padding(.leading, 2)
        }
        .padding(.horizontal, KatanaTheme.headerHorizontalPadding)
        .frame(height: KatanaTheme.headerHeight)
    }

    private var pageContent: some View {
        let split = TranscriptView.splitOutcome(page.messages)
        let hasOutcome = split.facts != nil || page.changeSummary != nil || !page.buttons.isEmpty
        return VStack(spacing: 0) {
            ScrollViewReader { proxy in
                SubtleScrollView {
                    TranscriptView(
                        messages: page.messages,
                        changeSummary: page.changeSummary,
                        buttons: page.buttons,
                        onButton: actions.button,
                        showsOutcome: false
                    )
                    .modifier(ColumnLayout())
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    Color.clear.frame(height: 1).id(Self.endID)
                }
                .defaultScrollAnchor(.bottom)
                .modifier(EdgeFade(top: KatanaTheme.topFade, topClear: KatanaTheme.topFadeClear))
                .onAppear {
                    // Once now, and once after text has been measured.
                    DispatchQueue.main.async { proxy.scrollTo(Self.endID, anchor: .bottom) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { proxy.scrollTo(Self.endID, anchor: .bottom) }
                }
                .onChange(of: page.messages.last?.id) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(Self.endID, anchor: .bottom)
                    }
                }
            }

            VStack(spacing: 10) {
                // The outcome stays in view above the composer; the status is under the title.
                if hasOutcome {
                    OutcomeCard(
                        facts: split.facts ?? [],
                        changeSummary: page.changeSummary,
                        buttons: page.buttons,
                        onButton: actions.button
                    )
                }
                KatanaComposer(
                    placeholder: "Write to \(page.agentName)…",
                    modelLabel: page.modelLabel,
                    onEffort: actions.setEffort,
                    isListening: listening,
                    onSend: actions.send,
                    onMicToggle: {
                        listening.toggle()
                        actions.micToggle(listening)
                    }
                )
            }
            .modifier(ColumnLayout())
            .padding(.top, hasOutcome ? 14 : 8)
            .padding(.bottom, KatanaTheme.footerBottomPadding)
            // A hairline marks the pinned footer when it holds the outcome card.
            .overlay(alignment: .top) {
                if hasOutcome { Rectangle().fill(KatanaTheme.paneBorder).frame(height: 1) }
            }
            // The transcript gives way first; the card and composer keep their height.
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
    }
}

extension TaskPageView where Browser == BrowserPlaceholder, Terminal == TerminalPlaceholder {
    /// With empty stand-ins for the browser and terminal tabs.
    public init(
        page: TaskPage,
        initialTab: TaskPageTab = .page,
        showsGoToIt: Bool = true,
        actions: TaskPageActions = TaskPageActions()
    ) {
        self.init(
            page: page,
            initialTab: initialTab,
            showsGoToIt: showsGoToIt,
            actions: actions,
            browser: { BrowserPlaceholder(caption: "The task's browser goes here") },
            terminal: { TerminalPlaceholder(caption: "The task's terminal goes here") }
        )
    }
}

extension TaskPageTab {
    var icon: PaneIcon {
        switch self {
        case .page: .page
        case .browser: .globe
        case .terminal: .terminal
        }
    }
}

/// "● Ready for review · 4m ago". `compact` is the small line under a task page's title.
struct TaskStatusRow: View {
    let status: TaskStatus
    let since: Date
    var compact = false

    var body: some View {
        HStack(spacing: 0) {
            TimelineView(.periodic(from: .now, by: 15)) { context in
                HStack(spacing: compact ? 6 : 7) {
                    StatusDot(status: status, size: compact ? 9 : 11, pulses: true)
                        .id(status)
                    Text("\(status.label) · \(Self.age(of: since, at: context.date, status: status))")
                }
            }
            Spacer(minLength: 0)
        }
        .font(compact ? KatanaTheme.smallFont : KatanaTheme.metaFont)
        .foregroundStyle(KatanaTheme.textSecondary)
        .padding(.leading, compact ? 0 : 8)
    }

    /// "4m ago" for a status that has ended, "4m" for one still running.
    static func age(of date: Date, at now: Date, status: TaskStatus) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let amount: String
        switch seconds {
        case ..<60: return status == .working ? "just started" : "just now"
        case ..<3600: amount = "\(seconds / 60)m"
        case ..<86_400: amount = "\(seconds / 3600)h"
        default: amount = "\(seconds / 86_400)d"
        }
        return status == .working ? amount : "\(amount) ago"
    }
}
