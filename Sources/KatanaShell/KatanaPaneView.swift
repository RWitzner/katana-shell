import SwiftUI

/// What Katana's pane asks the app to do.
public struct KatanaPaneActions {
    /// The user typed a message to Katana.
    public var send: (String) -> Void
    /// The mic button. The app flips `KatanaConversation.isListening`.
    public var micToggle: () -> Void
    /// The cancel button beside the mic while listening: stop and drop what was heard.
    /// Without it, cancel calls `micToggle`.
    public var cancelListening: (() -> Void)?
    /// The done button beside the mic while listening: stop and send what was heard.
    /// Without it, done calls `micToggle`.
    public var finishListening: (() -> Void)?
    /// An effort picked from the model menu in the composer ("low", "medium", "high").
    /// Without it, the model shows as a plain label.
    public var setEffort: ((String) -> Void)?
    /// The "Review" button on an event line about a task: open that task.
    public var openTask: ((UUID) -> Void)?

    public init(
        send: @escaping (String) -> Void = { _ in },
        micToggle: @escaping () -> Void = {},
        cancelListening: (() -> Void)? = nil,
        finishListening: (() -> Void)? = nil,
        setEffort: ((String) -> Void)? = nil,
        openTask: ((UUID) -> Void)? = nil
    ) {
        self.send = send
        self.micToggle = micToggle
        self.cancelListening = cancelListening
        self.finishListening = finishListening
        self.setEffort = setEffort
        self.openTask = openTask
    }
}

public enum KatanaPaneTab: String, CaseIterable, Sendable {
    case katana, browser, terminal

    var icon: PaneIcon {
        switch self {
        case .katana: .person
        case .browser: .globe
        case .terminal: .terminal
        }
    }
}

/// The middle pane: Katana's face, the conversation and the composer.
public struct KatanaPaneView<Browser: View, Terminal: View>: View {
    private let conversation: KatanaConversation
    private let avatar: Image?
    private let speakingAnimationURL: URL?
    private let backdrop: Image?
    private let actions: KatanaPaneActions
    private let browser: Browser
    private let terminal: Terminal
    @State private var tab: KatanaPaneTab = .katana

    /// `backdrop` is laid faintly behind the conversation, fading out toward the composer.
    public init(
        conversation: KatanaConversation,
        avatar: Image? = nil,
        speakingAnimationURL: URL? = nil,
        backdrop: Image? = nil,
        actions: KatanaPaneActions = KatanaPaneActions(),
        @ViewBuilder browser: () -> Browser,
        @ViewBuilder terminal: () -> Terminal
    ) {
        self.conversation = conversation
        self.avatar = avatar
        self.speakingAnimationURL = speakingAnimationURL
        self.backdrop = backdrop
        self.actions = actions
        self.browser = browser()
        self.terminal = terminal()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch tab {
                case .katana: chat
                case .browser: browser.padding(.top, KatanaTheme.headerHeight)
                case .terminal: terminal.padding(.top, KatanaTheme.headerHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 10) {
                KatanaAvatar(
                    image: avatar,
                    speakingAnimationURL: speakingAnimationURL,
                    isSpeaking: conversation.isSpeaking,
                    size: KatanaTheme.headerAvatarSize
                )
                .scaleEffect(KatanaTheme.sidebarAvatarScale)
                .frame(width: KatanaTheme.headerAvatarSize, height: KatanaTheme.headerAvatarSize)
                .clipped()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Katana")
                        .font(KatanaTheme.titleFont)
                        .foregroundStyle(KatanaTheme.textTitle)
                    KatanaStateLine(conversation: conversation)
                }
                .animation(.easeOut(duration: 0.2), value: conversation.isListening)
                Spacer()
                PaneTabs(tabs: KatanaPaneTab.allCases, selection: tab, icon: \.icon) { tab = $0 }
            }
            .padding(.leading, -4)
            .padding(.horizontal, KatanaTheme.headerHorizontalPadding)
            .frame(height: KatanaTheme.headerHeight)
        }
    }

    /// Katana's newest line stays bright; older ones step back.
    private var latestKatanaID: UUID? {
        conversation.messages.last { if case .katana = $0.kind { true } else { false } }?.id
    }

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: KatanaTheme.katanaMessageSpacing) {
                        ForEach(conversation.messages) { message in
                            KatanaMessageView(
                                message: message,
                                isLatest: message.id == latestKatanaID,
                                openTask: actions.openTask
                            )
                            .id(message.id)
                        }
                        if conversation.isThinking {
                            ThinkingDash().id("thinking")
                        }
                    }
                    .textSelection(.enabled)
                    .modifier(ColumnLayout(inset: KatanaTheme.katanaInset))
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                    Color.clear.frame(height: 1).id("katana-end")
                }
                .scrollIndicators(.never)
                .defaultScrollAnchor(.bottom)
                .modifier(EdgeFade(top: KatanaTheme.topFade, topClear: KatanaTheme.topFadeClear, bottom: 32))
                .padding(.top, KatanaTheme.headerHeight)
                .onAppear {
                    // Once now, and once after text has been measured.
                    DispatchQueue.main.async { proxy.scrollTo("katana-end", anchor: .bottom) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { proxy.scrollTo("katana-end", anchor: .bottom) }
                }
                .onChange(of: conversation.messages.count + (conversation.isThinking ? 1 : 0)) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("katana-end", anchor: .bottom) }
                }
            }

            VStack(spacing: 0) {
                KatanaComposer(
                    placeholder: "Talk to Katana, or write…",
                    hint: "space",
                    modelLabel: conversation.modelLabel,
                    onEffort: actions.setEffort,
                    isListening: conversation.isListening,
                    onSend: actions.send,
                    onMicToggle: actions.micToggle,
                    voice: VoiceActions(
                        start: actions.micToggle,
                        cancel: actions.cancelListening ?? actions.micToggle,
                        finish: actions.finishListening ?? actions.micToggle
                    )
                )
            }
            .modifier(ColumnLayout(inset: KatanaTheme.katanaInset))
            .padding(.top, 8)
            .padding(.bottom, KatanaTheme.footerBottomPadding)
        }
        .background {
            if let backdrop { PaneBackdrop(image: backdrop) }
        }
    }
}

extension KatanaPaneView where Browser == BrowserPlaceholder, Terminal == TerminalPlaceholder {
    /// With empty stand-ins for Katana's browser and terminal tabs.
    public init(conversation: KatanaConversation, avatar: Image? = nil, speakingAnimationURL: URL? = nil, backdrop: Image? = nil, actions: KatanaPaneActions = KatanaPaneActions()) {
        self.init(
            conversation: conversation,
            avatar: avatar,
            speakingAnimationURL: speakingAnimationURL,
            backdrop: backdrop,
            actions: actions,
            browser: { BrowserPlaceholder(caption: "Katana's browser goes here") },
            terminal: { TerminalPlaceholder(caption: "Katana's terminal goes here") }
        )
    }
}

private struct KatanaMessageView: View {
    let message: KatanaMessage
    var isLatest = true
    var openTask: ((UUID) -> Void)? = nil

    var body: some View {
        switch message.kind {
        case .katana(let markdown):
            InlineText(markdown, color: isLatest ? KatanaTheme.textPrimary : KatanaTheme.earlierText)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .user(let text, let notes):
            VStack(alignment: .trailing, spacing: 10) {
                UserBubble { InlineText(text) }
                if !notes.isEmpty {
                    ContextNotes(notes: notes)
                        .padding(.leading, 48)
                }
            }
        case .event(let text, let status, let taskID):
            EventRow(text: text, status: status, open: taskID.flatMap { id in openTask.map { open in { open(id) } } })
        }
    }
}

/// A task event in Katana's conversation, set apart as a small row: status dot,
/// what happened, and a button to open the task when there is one.
private struct EventRow: View {
    let text: String
    let status: TaskStatus
    let open: (() -> Void)?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        HStack(spacing: 9) {
            StatusDot(status: status, size: 9)
            Text(text)
                .font(KatanaTheme.metaFont)
                .foregroundStyle(KatanaTheme.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 8)
            if let open {
                GhostButton(title: status.needsUser ? "Review" : "Open", action: open)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, open == nil ? 12 : 4)
        .frame(minHeight: 36)
        .background(shape.fill(KatanaTheme.eventFill))
        .overlay(shape.strokeBorder(KatanaTheme.paneBorder, lineWidth: 1))
    }
}

/// "Ready", "Listening", "Speaking" or "Thinking" under "Katana" in her header.
private struct KatanaStateLine: View {
    let conversation: KatanaConversation

    var body: some View {
        HStack(spacing: 6) {
            if conversation.isListening {
                Circle().fill(KatanaTheme.listening).frame(width: 7, height: 7)
            }
            Text(label)
        }
        .font(KatanaTheme.smallFont)
        .foregroundStyle(KatanaTheme.textSecondary)
    }

    private var label: String {
        if conversation.isListening { return "Listening" }
        if conversation.isSpeaking { return "Speaking" }
        if conversation.isThinking { return "Thinking…" }
        return "Ready"
    }
}

/// What Katana sent along with the user's message ("Beside you: …", what the
/// mic heard): small and quiet under the bubble, behind a thin rule.
private struct ContextNotes: View {
    let notes: [String]
    @State private var expanded = false
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button { withAnimation(.easeOut(duration: 0.18)) { expanded.toggle() } } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8.5, weight: .bold))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                    Text("Context sent along · \(notes.count) \(notes.count == 1 ? "note" : "notes")")
                        .font(KatanaTheme.noteFont)
                }
                .foregroundStyle(hovering ? KatanaTheme.textSecondary : KatanaTheme.textTertiary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
            .accessibilityLabel(expanded ? "Hide context sent along" : "Show context sent along")

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        Text(note)
                            .font(KatanaTheme.noteFont)
                            .foregroundStyle(KatanaTheme.textTertiary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 11)
                .overlay(alignment: .leading) {
                    Capsule().fill(KatanaTheme.raisedBorder).frame(width: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
        }
        .padding(.trailing, 4)
    }
}

/// A picture filling the pane, blurred, dimmed and fading out toward the bottom.
/// Works best with a picture on a background close to `paneBackground`.
private struct PaneBackdrop: View {
    let image: Image

    var body: some View {
        GeometryReader { geometry in
            image
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .blur(radius: KatanaTheme.backdropBlur)
                .opacity(KatanaTheme.backdropOpacity)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: KatanaTheme.backdropFadeStart),
                            .init(color: .clear, location: KatanaTheme.backdropFadeEnd),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The short dash under the last message while Katana works on a reply.
private struct ThinkingDash: View {
    @State private var dim = false

    var body: some View {
        Capsule()
            .fill(KatanaTheme.textPrimary)
            .frame(width: 16, height: 2)
            .opacity(dim ? 0.25 : 0.9)
            .padding(.vertical, 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { dim = true }
            }
            .accessibilityLabel("Katana is thinking")
    }
}
