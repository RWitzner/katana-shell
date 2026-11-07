import SwiftUI

/// Everything the main window asks the app to do.
public struct WorkspaceActions {
    public var sidebar: SidebarActions
    public var katana: KatanaPaneActions
    /// Close the task page beside Katana.
    public var closeBeside: () -> Void
    /// A message to a task's agent.
    public var sendToTask: (UUID, String) -> Void
    /// A task's mic button turned on or off.
    public var taskMicToggle: (UUID, Bool) -> Void
    /// One of a task's buttons ("merge", "pr", "done"…), by id.
    public var taskButton: (UUID, String) -> Void
    /// An effort picked from a task composer's model menu. Without it, the model is a plain label.
    public var taskEffort: ((UUID, String) -> Void)?

    public init(
        sidebar: SidebarActions = SidebarActions(),
        katana: KatanaPaneActions = KatanaPaneActions(),
        closeBeside: @escaping () -> Void = {},
        sendToTask: @escaping (UUID, String) -> Void = { _, _ in },
        taskMicToggle: @escaping (UUID, Bool) -> Void = { _, _ in },
        taskButton: @escaping (UUID, String) -> Void = { _, _ in },
        taskEffort: ((UUID, String) -> Void)? = nil
    ) {
        self.sidebar = sidebar
        self.katana = katana
        self.closeBeside = closeBeside
        self.sendToTask = sendToTask
        self.taskMicToggle = taskMicToggle
        self.taskButton = taskButton
        self.taskEffort = taskEffort
    }
}

/// The main window: sidebar, then Katana (or the task you went to), then the
/// task page beside it when one is open.
///
/// Put this as the root of a window with a hidden title bar; the sidebar leaves
/// room for the traffic lights.
public struct KatanaWorkspaceView: View {
    let tasks: [TaskPage]
    let selection: WorkspaceSelection
    let besideTaskID: UUID?
    let conversation: KatanaConversation
    let footer: WorkspaceFooter
    let avatar: Image?
    let speakingAnimationURL: URL?
    let katanaBackdrop: Image?
    let actions: WorkspaceActions

    /// `katanaBackdrop` is laid faintly behind Katana's conversation.
    public init(
        tasks: [TaskPage],
        selection: WorkspaceSelection,
        besideTaskID: UUID?,
        conversation: KatanaConversation,
        footer: WorkspaceFooter,
        avatar: Image? = nil,
        speakingAnimationURL: URL? = nil,
        katanaBackdrop: Image? = nil,
        actions: WorkspaceActions = WorkspaceActions()
    ) {
        self.tasks = tasks
        self.selection = selection
        self.besideTaskID = besideTaskID
        self.conversation = conversation
        self.footer = footer
        self.avatar = avatar
        self.speakingAnimationURL = speakingAnimationURL
        self.katanaBackdrop = katanaBackdrop
        self.actions = actions
    }

    public var body: some View {
        GeometryReader { geometry in
            panes(width: geometry.size.width)
        }
        .frame(minWidth: KatanaTheme.workspaceMinWidth)
    }

    private func panes(width: CGFloat) -> some View {
        // Katana gets up to `katanaPaneWidth`, but never squeezes the task page below its minimum.
        let rest = width - KatanaTheme.windowPadding * 2 - KatanaTheme.sidebarWidth - KatanaTheme.paneGap * 2
        let katanaWidth = min(KatanaTheme.katanaPaneWidth, max(KatanaTheme.katanaPaneMinWidth, rest - KatanaTheme.taskPaneMinWidth))

        return HStack(spacing: KatanaTheme.paneGap) {
            KatanaSidebar(
                tasks: tasks,
                selection: selection,
                besideTaskID: besideTask?.id,
                footer: footer,
                avatar: avatar,
                speakingAnimationURL: speakingAnimationURL,
                isSpeaking: conversation.isSpeaking,
                actions: actions.sidebar
            )
            // No pane: the sidebar sits on the window frame and its glow.
            .frame(width: KatanaTheme.sidebarWidth)

            middle
                .frame(width: besideTask == nil ? nil : katanaWidth)
                .frame(maxWidth: besideTask == nil ? .infinity : katanaWidth, maxHeight: .infinity)

            if let besideTask {
                taskPage(besideTask, showsGoToIt: true, close: actions.closeBeside)
                    .id(besideTask.id)
                    .katanaPane()
                    .frame(minWidth: KatanaTheme.taskPaneMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(KatanaTheme.windowPadding)
        .katanaWindowBackground()
        .animation(.easeOut(duration: 0.22), value: besideTask?.id)
        .animation(.easeOut(duration: 0.22), value: selection)
    }

    /// The beside task, unless it's the one already shown in the middle.
    private var besideTask: TaskPage? {
        guard let besideTaskID, selection != .task(besideTaskID) else { return nil }
        return tasks.first { $0.id == besideTaskID }
    }

    @ViewBuilder
    private var middle: some View {
        switch selection {
        case .katana:
            // No colored pane edge while listening: the mic's pill and the dot under the face show it.
            katanaPane
                .katanaPane()
        case .task(let id):
            if let task = tasks.first(where: { $0.id == id }) {
                taskPage(task, showsGoToIt: false, close: actions.sidebar.selectKatana)
                    .id(task.id)
                    .katanaPane()
            } else {
                katanaPane
                    .katanaPane()
            }
        }
    }

    private var katanaPane: some View {
        KatanaPaneView(
            conversation: conversation,
            avatar: avatar,
            speakingAnimationURL: speakingAnimationURL,
            backdrop: katanaBackdrop,
            actions: actions.katana
        )
    }

    private func taskPage(_ task: TaskPage, showsGoToIt: Bool, close: @escaping () -> Void) -> some View {
        TaskPageView(
            page: task,
            showsGoToIt: showsGoToIt,
            actions: TaskPageActions(
                send: { actions.sendToTask(task.id, $0) },
                micToggle: { actions.taskMicToggle(task.id, $0) },
                goToIt: { actions.sidebar.goToTask(task.id) },
                close: close,
                button: { actions.taskButton(task.id, $0) },
                setEffort: actions.taskEffort.map { pick in { pick(task.id, $0) } }
            )
        )
    }
}
