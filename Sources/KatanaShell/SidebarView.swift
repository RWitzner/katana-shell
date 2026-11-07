import SwiftUI

/// What the sidebar asks the app to do.
public struct SidebarActions {
    public var newTask: () -> Void
    /// The Katana card.
    public var selectKatana: () -> Void
    /// A task row: open its page beside Katana.
    public var openTask: (UUID) -> Void
    /// "Go to it" from a row's menu: show the task in the middle.
    public var goToTask: (UUID) -> Void
    /// "Open in New Window" from a row's menu.
    public var openTaskInWindow: (UUID) -> Void
    /// An item from the "···" menu, by title.
    public var menuItem: (String) -> Void

    public init(
        newTask: @escaping () -> Void = {},
        selectKatana: @escaping () -> Void = {},
        openTask: @escaping (UUID) -> Void = { _ in },
        goToTask: @escaping (UUID) -> Void = { _ in },
        openTaskInWindow: @escaping (UUID) -> Void = { _ in },
        menuItem: @escaping (String) -> Void = { _ in }
    ) {
        self.newTask = newTask
        self.selectKatana = selectKatana
        self.openTask = openTask
        self.goToTask = goToTask
        self.openTaskInWindow = openTaskInWindow
        self.menuItem = menuItem
    }
}

/// Left column: new task, the Katana card, the task list and the usage footer.
/// Leaves room top-left for the window's traffic lights.
public struct KatanaSidebar: View {
    let tasks: [TaskPage]
    let selection: WorkspaceSelection
    let besideTaskID: UUID?
    let footer: WorkspaceFooter
    let avatar: Image?
    let speakingAnimationURL: URL?
    let isSpeaking: Bool
    let actions: SidebarActions

    public static let menuItems = ["Settings…", "Voices…", "Usage…", "Switch Account…"]

    public init(
        tasks: [TaskPage],
        selection: WorkspaceSelection,
        besideTaskID: UUID? = nil,
        footer: WorkspaceFooter,
        avatar: Image? = nil,
        speakingAnimationURL: URL? = nil,
        isSpeaking: Bool = false,
        actions: SidebarActions = SidebarActions()
    ) {
        self.tasks = tasks
        self.selection = selection
        self.besideTaskID = besideTaskID
        self.footer = footer
        self.avatar = avatar
        self.speakingAnimationURL = speakingAnimationURL
        self.isSpeaking = isSpeaking
        self.actions = actions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                NewTaskButton(action: actions.newTask)
            }
            .padding(.horizontal, 9)
            .frame(height: KatanaTheme.headerHeight)

            KatanaCard(
                subtitle: Self.cardSubtitleText(tasks),
                avatar: avatar,
                speakingAnimationURL: speakingAnimationURL,
                isSpeaking: isSpeaking,
                isSelected: selection == .katana,
                action: actions.selectKatana
            )
            .padding(.horizontal, 9)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(groups, id: \.title) { group in
                        taskGroup(group.title, group.tasks)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.never)

            SidebarFooter(footer: footer, menuItem: actions.menuItem)
        }
    }

    /// "Needs you", "At work", then "Finished" and failed; empty groups are left out.
    private var groups: [(title: String, tasks: [TaskPage])] {
        [
            ("Needs you", tasks.filter { $0.status.needsUser }),
            ("At work", tasks.filter { $0.status == .working }),
            ("Finished", tasks.filter { !$0.status.isActive }),
        ].filter { !$0.tasks.isEmpty }
    }

    private func taskGroup(_ title: String, _ group: [TaskPage]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(title)
                    .foregroundStyle(title == "Needs you" ? KatanaTheme.needsYou : KatanaTheme.textSecondary)
                Text("\(group.count)")
                    .foregroundStyle(KatanaTheme.textTertiary)
            }
            .font(KatanaTheme.groupLabelFont)
            .padding(.leading, 11)
            .padding(.bottom, 6)
            ForEach(group) { task in
                TaskRow(
                    task: task,
                    isSelected: selection == .task(task.id),
                    isBeside: besideTaskID == task.id,
                    showsSummary: task.status.isActive,
                    actions: actions
                )
            }
        }
        .padding(.horizontal, 9)
    }

    /// `cardSubtitle` with the "needs you" part in amber.
    static func cardSubtitleText(_ tasks: [TaskPage]) -> Text? {
        guard let line = cardSubtitle(tasks) else { return nil }
        let needs = tasks.filter { $0.status.needsUser }.count
        guard needs > 0 else { return Text(line) }
        let parts = line.components(separatedBy: " · ")
        var text = AttributedString(parts[0])
        text.foregroundColor = KatanaTheme.needsYou
        if parts.count > 1 { text += AttributedString(" · " + parts.dropFirst().joined(separator: " · ")) }
        return Text(text)
    }

    /// "Nothing needs you · 2 at work", or nothing when the list is quiet.
    static func cardSubtitle(_ tasks: [TaskPage]) -> String? {
        let needs = tasks.filter { $0.status.needsUser }.count
        let working = tasks.filter { $0.status == .working }.count
        guard needs > 0 || working > 0 else { return nil }
        let first = needs == 0 ? "Nothing needs you" : (needs == 1 ? "1 needs you" : "\(needs) need you")
        return working > 0 ? "\(first) · \(working) at work" : first
    }
}

private struct NewTaskButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KatanaTheme.buttonCornerRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 11.5, weight: .semibold))
                Text("New task").font(.system(size: 13, weight: .medium))
                Text("⌘N").font(.system(size: 11)).foregroundStyle(KatanaTheme.textTertiary)
            }
            .foregroundStyle(KatanaTheme.textTitle)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(shape.fill(hovering ? KatanaTheme.raised : KatanaTheme.secondaryButton))
            .overlay(shape.strokeBorder(KatanaTheme.raisedBorder, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .keyboardShortcut("n", modifiers: .command)
        .help("New task (⌘N)")
    }
}

private struct KatanaCard: View {
    let subtitle: Text?
    let avatar: Image?
    let speakingAnimationURL: URL?
    let isSpeaking: Bool
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        Button(action: action) {
            HStack(spacing: 13) {
                KatanaAvatar(
                    image: avatar,
                    speakingAnimationURL: speakingAnimationURL,
                    isSpeaking: isSpeaking,
                    size: KatanaTheme.sidebarAvatarSize
                )
                    .scaleEffect(KatanaTheme.sidebarAvatarScale)
                    .frame(width: KatanaTheme.sidebarAvatarSize, height: KatanaTheme.sidebarAvatarSize)
                    .clipped()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Katana")
                        .font(KatanaTheme.cardTitleFont)
                        .foregroundStyle(KatanaTheme.textStrong)
                    if let subtitle {
                        subtitle
                            .font(KatanaTheme.metaFont)
                            .foregroundStyle(KatanaTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(shape.fill(hovering ? KatanaTheme.hover : KatanaTheme.sidebarCard))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Finished rows leave out their second line: they need less detail.
private struct TaskRow: View {
    let task: TaskPage
    let isSelected: Bool
    let isBeside: Bool
    var showsSummary = true
    let actions: SidebarActions
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        Button { actions.openTask(task.id) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                StatusDot(status: task.status, size: 10)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(task.title)
                            .font(KatanaTheme.rowTitleFont)
                            .foregroundStyle(KatanaTheme.textPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            Text(RelativeAge.short(since: task.statusSince, now: context.date))
                                .font(KatanaTheme.smallFont)
                                .foregroundStyle(KatanaTheme.textTertiary)
                                .monospacedDigit()
                        }
                        .fixedSize()
                    }
                    if showsSummary, let summary = task.summary {
                        Text(summary)
                            .font(KatanaTheme.metaFont)
                            .foregroundStyle(KatanaTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, 11)
            .padding(.trailing, 12)
            .padding(.vertical, 9)
            .background(shape.fill(background))
            .overlay(shape.strokeBorder(isSelected || isBeside ? KatanaTheme.raisedBorder : .clear, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Open Beside Katana") { actions.openTask(task.id) }
            Button("Go to It") { actions.goToTask(task.id) }
            Button("Open in New Window") { actions.openTaskInWindow(task.id) }
        }
    }

    private var background: Color {
        if isSelected || isBeside { return KatanaTheme.rowSelected }
        return hovering ? KatanaTheme.hover : .clear
    }
}

private struct SidebarFooter: View {
    let footer: WorkspaceFooter
    let menuItem: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let devLine = footer.devBuildLine {
                HStack(spacing: 8) {
                    Text("DEV")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(KatanaTheme.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(KatanaTheme.raisedBorder, lineWidth: 1))
                    // The build only; the commit subject is in the tooltip.
                    Text(devLine.components(separatedBy: " · ")[0])
                        .font(KatanaTheme.smallFont)
                        .foregroundStyle(KatanaTheme.textTertiary)
                        .lineLimit(1)
                        .help(devLine)
                }
            }
            HStack(spacing: 0) {
                HStack(spacing: 1) {
                    Text("›").foregroundStyle(KatanaTheme.textSecondary)
                    Text("katana").foregroundStyle(KatanaTheme.textTitle)
                }
                .font(.system(size: 13))
                Spacer(minLength: 8)
                UsageMeter(fraction: footer.usage)
                    .padding(.trailing, 8)
                Text(footer.usageLabel)
                    .font(KatanaTheme.smallFont)
                    .foregroundStyle(KatanaTheme.textSecondary)
                Menu {
                    ForEach(KatanaSidebar.menuItems, id: \.self) { item in
                        Button(item) { menuItem(item) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KatanaTheme.textSecondary)
                        .frame(width: 26, height: 22)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .padding(.leading, 12)
            }
        }
        .padding(.leading, 22)
        .padding(.trailing, 14)
        .padding(.bottom, 14)
        .padding(.top, 8)
    }
}

/// A thin bar: the used share filled, the rest a faint track.
private struct UsageMeter: View {
    let fraction: Double

    var body: some View {
        let used = min(max(fraction, 0), 1)
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.12))
            Capsule().fill(KatanaTheme.textSecondary).frame(width: 40 * used)
        }
        .frame(width: 40, height: 3)
        .accessibilityLabel("Usage \(Int(fraction * 100)) percent")
    }
}
