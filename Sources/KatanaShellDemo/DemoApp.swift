import AppKit
import KatanaShell
import SwiftUI

/// Katana's window with made-up content. Every button does something,
/// but nothing talks to a model or an agent.
@main
struct KatanaShellDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DemoStore()

    var body: some Scene {
        Window("Katana", id: "main") {
            MainWindow(store: store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1500, height: 900)
        .commands { DemoCommands(store: store) }

        // A task page in a window of its own.
        WindowGroup("Task", id: "task", for: UUID.self) { $id in
            if let id {
                TaskWindow(store: store, taskID: id)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 860)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Started with `swift run` there is no app bundle, so ask to be a normal app.
        NSApp.setActivationPolicy(.regular)
        // Set KATANA_DEMO_BACKGROUND=1 to launch without taking focus (for automated checks).
        if ProcessInfo.processInfo.environment["KATANA_DEMO_BACKGROUND"] == nil {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct MainWindow: View {
    @ObservedObject var store: DemoStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        KatanaWorkspaceView(
            tasks: store.tasks,
            selection: store.selection,
            besideTaskID: store.besideTaskID,
            conversation: store.conversation,
            footer: MockData.footer,
            avatar: DemoAvatar.idle,
            speakingAnimationURL: DemoAvatar.speakingURL,
            actions: WorkspaceActions(
                sidebar: SidebarActions(
                    newTask: { store.showingNewTask = true },
                    selectKatana: { store.selectKatana() },
                    openTask: { store.openBeside($0) },
                    goToTask: { store.goTo($0) },
                    openTaskInWindow: { openInWindow($0) },
                    menuItem: { store.showToast("\($0) would open here") }
                ),
                katana: KatanaPaneActions(
                    send: { store.sendToKatana($0) },
                    micToggle: { store.toggleKatanaMic() },
                    cancelListening: { store.cancelKatanaListening() },
                    finishListening: { store.finishKatanaListening() },
                    setEffort: { store.setKatanaEffort($0) },
                    openTask: { store.openBeside($0) }
                ),
                closeBeside: { store.closeBeside() },
                sendToTask: { store.sendToTask($0, $1) },
                taskMicToggle: { _, on in store.showToast(on ? "Talking to the task’s agent" : "Mic off") },
                taskButton: { store.taskButton($0, $1) },
                taskEffort: { store.setTaskEffort($0, $1) }
            )
        )
        .ignoresSafeArea(.container, edges: .top)
        .background(WindowSetup(hidesTrafficLights: false))
        .frame(minHeight: 620)
        .overlay(alignment: .top) { Toast(message: store.toast) }
        .sheet(isPresented: $store.showingNewTask) {
            NewTaskSheet(
                onStart: { store.startTask(prompt: $0, model: $1) },
                onCancel: { store.showingNewTask = false }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTaskWindow)) { note in
            if let id = note.object as? UUID { openInWindow(id) }
        }
    }

    private func openInWindow(_ id: UUID) {
        openWindow(id: "task", value: id)
        if store.besideTaskID == id { store.closeBeside() }
        if store.selection == .task(id) { store.selectKatana() }
    }
}

/// A task page on its own: no traffic lights, since the page has its own close button.
struct TaskWindow: View {
    @ObservedObject var store: DemoStore
    let taskID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if let task = store.task(taskID) {
                TaskPageView(
                    page: task,
                    actions: TaskPageActions(
                        send: { store.sendToTask(taskID, $0) },
                        goToIt: {
                            store.goTo(taskID)
                            openWindow(id: "main")
                            dismiss()
                        },
                        close: { dismiss() },
                        button: { store.taskButton(taskID, $0) },
                        setEffort: { store.setTaskEffort(taskID, $0) }
                    ),
                    browser: { BrowserPlaceholder(caption: "The task's browser goes here") },
                    terminal: { MockTerminal() }
                )
                .katanaPane()
            } else {
                Text("This task is gone.")
                    .foregroundStyle(KatanaTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .katanaPane()
            }
        }
        .padding(6)
        .katanaWindowBackground()
        .ignoresSafeArea(.container, edges: .top)
        .background(WindowSetup(hidesTrafficLights: true))
        .frame(minWidth: 520, minHeight: 420)
        .onChange(of: store.task(taskID) == nil) { _, gone in
            if gone { dismiss() }
        }
    }
}

@MainActor
private enum DemoAvatar {
    static let idle: Image? = {
        guard let url = Bundle.module.url(forResource: "katana-avatar-reference-v1", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: image)
    }()

    static let speakingURL = Bundle.module.url(forResource: "katana-avatar-talking-v1", withExtension: "gif")
}

struct DemoCommands: Commands {
    @ObservedObject var store: DemoStore

    var body: some Commands {
        // ⌘N is "+ New task", not a new window.
        CommandGroup(replacing: .newItem) {}
        CommandMenu("Task") {
            Button("Open Beside Task in New Window") {
                if let id = store.besideTaskID {
                    NotificationCenter.default.post(name: .openTaskWindow, object: id)
                }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .disabled(store.besideTaskID == nil)
            Button("Close Beside Task") { store.closeBeside() }
                .keyboardShortcut("w", modifiers: [.command, .option])
                .disabled(store.besideTaskID == nil)
            Divider()
            Menu("Demo: Set Status") {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Button(status.label) { store.setBesideStatus(status) }
                }
            }
            Button("Demo: Reset") { store.reset() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
        }
        CommandMenu("Katana") {
            Button(store.conversation.isListening ? "Stop Listening" : "Start Listening") { store.toggleKatanaMic() }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            Button(store.conversation.isSpeaking ? "Demo: Stop Speaking" : "Demo: Speak") {
                if store.conversation.isSpeaking {
                    store.stopSpeaking()
                } else {
                    store.previewSpeech()
                }
            }
            Button("Show Katana") { store.selectKatana() }
                .keyboardShortcut("0", modifiers: .command)
        }
    }
}

extension Notification.Name {
    static let openTaskWindow = Notification.Name("KatanaShellDemo.openTaskWindow")
}

private struct Toast: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(KatanaTheme.metaFont)
                .foregroundStyle(KatanaTheme.textTitle)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(KatanaTheme.card))
                .overlay(Capsule().strokeBorder(KatanaTheme.raisedBorder, lineWidth: 1))
                .padding(.top, 18)
                .transition(.opacity)
        }
    }
}

/// Stands in for a task's terminal.
struct MockTerminal: View {
    var body: some View {
        SubtleScrollView {
            Text(MockData.terminalLines)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(Color(katanaHex: 0xCACBCE))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .textSelection(.enabled)
        }
        .defaultScrollAnchor(.bottom)
        .background(KatanaTheme.paneBackground)
    }
}

/// Lets the window be dragged from its background, and hides the traffic
/// lights where the page has its own close button.
private struct WindowSetup: NSViewRepresentable {
    let hidesTrafficLights: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(KatanaTheme.windowBackground)
            if hidesTrafficLights {
                for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                    window.standardWindowButton(kind)?.isHidden = true
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
