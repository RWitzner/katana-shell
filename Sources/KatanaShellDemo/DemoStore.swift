import Foundation
import KatanaShell

/// Holds the demo's state and fakes what Katana and the agents would do.
/// Nothing here talks to a model; every reply is canned.
@MainActor
final class DemoStore: ObservableObject {
    @Published var tasks = MockData.tasks()
    @Published var selection: WorkspaceSelection = .katana
    @Published var besideTaskID: UUID? = MockData.hangUpID
    @Published var conversation = MockData.conversation()
    @Published var showingNewTask = false
    @Published var toast: String?

    private var timers: [Task<Void, Never>] = []
    private var speechTask: Task<Void, Never>?

    init() {
        // Katana finishes the reply that is "in progress" in the mock conversation.
        later(2.5) { store in
            store.say("Ready. Fast mode is on today, so I’ll keep answers short.")
        }
        // The mute task finishes while you watch, and Katana tells you.
        later(25) { store in store.finishMuteTask() }
    }

    func task(_ id: UUID) -> TaskPage? { tasks.first { $0.id == id } }

    // MARK: Sidebar

    func selectKatana() { selection = .katana }

    func openBeside(_ id: UUID) {
        if selection == .task(id) { selection = .katana }
        besideTaskID = id
    }

    func goTo(_ id: UUID) {
        selection = .task(id)
        if besideTaskID == id { besideTaskID = nil }
    }

    func closeBeside() { besideTaskID = nil }

    func startTask(prompt: String, model: String) {
        showingNewTask = false
        let words = prompt.split(separator: " ").prefix(6).joined(separator: " ")
        let modelName = model == "Defaults" ? "Opus 5.5" : model
        let page = TaskPage(
            title: words.prefix(1).uppercased() + words.dropFirst(),
            summary: "Just started",
            status: .working,
            agentName: modelName.hasPrefix("GPT") ? "Codex" : "Claude",
            modelLabel: "\(modelName) · high effort · claude1",
            messages: [.user(prompt)]
        )
        tasks.insert(page, at: 0)
        openBeside(page.id)
        conversation.messages.append(KatanaMessage(.event("Started “\(page.title)”", status: .working, taskID: page.id)))
        later(2) { store in
            store.update(page.id) { $0.messages.append(.agent("Reading the code this touches first.")); $0.summary = "Reading the code" }
        }
    }

    // MARK: Katana

    func sendToKatana(_ text: String) {
        stopSpeaking()
        var notes: [String] = []
        if let beside = besideTaskID.flatMap(task) {
            notes.append("Beside you: \(beside.title), a task’s page.")
        }
        conversation.messages.append(KatanaMessage(.user(text, notes: notes)))
        conversation.isThinking = true
        later(1.4) { store in
            store.say("Got it. This is the demo, so I can’t act on that, but in Katana I’d answer here and start or steer a task.")
        }
    }

    func toggleKatanaMic() {
        conversation.isListening.toggle()
    }

    /// The cancel button beside the mic: stop listening and drop what was heard.
    func cancelKatanaListening() {
        conversation.isListening = false
    }

    /// The done button beside the mic: stop listening and send a canned line as if it was heard.
    func finishKatanaListening() {
        conversation.isListening = false
        sendToKatana("Is the mute change ready to try?")
    }

    func previewSpeech() {
        selectKatana()
        say("This is Katana speaking. The portrait animates while I reply and returns to the still image when I finish.")
    }

    func stopSpeaking() {
        speechTask?.cancel()
        speechTask = nil
        conversation.isSpeaking = false
    }

    /// A silent speech simulation. The real app should use audio playback events.
    private func say(_ text: String) {
        stopSpeaking()
        conversation.isThinking = false
        conversation.messages.append(KatanaMessage(.katana(text)))
        conversation.isSpeaking = true
        let duration = min(12, max(3, Double(text.split(whereSeparator: \.isWhitespace).count) / 2.7))
        speechTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, !Task.isCancelled else { return }
            self.conversation.isSpeaking = false
            self.speechTask = nil
        }
    }

    // MARK: Tasks

    func sendToTask(_ id: UUID, _ text: String) {
        update(id) {
            $0.messages.append(.user(text))
            $0.status = .working
            $0.statusSince = .now
        }
        later(1.2) { store in store.update(id) { $0.messages.append(.agent("On it. Looking at that now.")) } }
        later(3.6) { store in
            store.update(id) {
                $0.messages.append(TranscriptMessage(isReport: true, blocks: [
                    .paragraph("**Done.** This is a canned reply from the demo; in Katana the agent answers here."),
                ]))
                $0.status = .finished
                $0.statusSince = .now
            }
        }
    }

    func taskButton(_ id: UUID, _ button: String) {
        switch button {
        case "merge":
            update(id) {
                $0.messages.append(.agent("Merged into main and restarted the daemon. The faster hang-up is live on your next call."))
                $0.changeSummary = "Merged · " + ($0.changeSummary ?? "")
                $0.buttons.removeAll { $0.id == "merge" || $0.id == "pr" }
                $0.summary = "Merged into main"
                $0.status = .finished
                $0.statusSince = .now
            }
        case "pr":
            update(id) {
                $0.messages.append(.agent("Opened pull request #128 from this task’s branch."))
                $0.buttons.removeAll { $0.id == "pr" }
            }
        case "done":
            let title = task(id)?.title ?? "Task"
            tasks.removeAll { $0.id == id }
            if besideTaskID == id { besideTaskID = nil }
            if selection == .task(id) { selection = .katana }
            showToast("“\(title)” moved out of the list")
        default:
            break
        }
    }

    // MARK: Effort

    func setKatanaEffort(_ effort: String) {
        conversation.modelLabel = Self.label(conversation.modelLabel, effort: effort)
    }

    func setTaskEffort(_ id: UUID, _ effort: String) {
        update(id) { $0.modelLabel = Self.label($0.modelLabel, effort: effort) }
    }

    /// "Opus 5.5 · high effort · claude1" with the effort swapped.
    static func label(_ label: String, effort: String) -> String {
        var parts = label.components(separatedBy: " · ")
        if let index = parts.firstIndex(where: { $0.hasSuffix(" effort") }) {
            parts[index] = "\(effort) effort"
        } else {
            parts.insert("\(effort) effort", at: min(1, parts.count))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Helpers

    func showToast(_ message: String) {
        toast = message
        later(1.8) { store in if store.toast == message { store.toast = nil } }
    }

    func setBesideStatus(_ status: TaskStatus) {
        guard let id = besideTaskID ?? { if case .task(let id) = selection { return id } else { return nil } }() else { return }
        update(id) { $0.status = status; $0.statusSince = .now }
    }

    func reset() {
        stopSpeaking()
        timers.forEach { $0.cancel() }
        timers.removeAll()
        tasks = MockData.tasks()
        selection = .katana
        besideTaskID = MockData.hangUpID
        conversation = MockData.conversation()
        conversation.isThinking = false
    }

    private func finishMuteTask() {
        guard task(MockData.muteID)?.status == .working else { return }
        update(MockData.muteID) {
            $0.status = .review
            $0.statusSince = .now
            $0.summary = "On mute-keeps-katana-talking"
            $0.messages.append(TranscriptMessage(isReport: true, blocks: [
                .paragraph("**Mute: built. When you mute, Katana stops hearing you and keeps talking.**"),
                .facts([
                    TaskFact("You asked", "Mute that stops Katana hearing you, not speaking.", detail: "11m ago"),
                    TaskFact("Where it is", "On its branch, all daemon suites pass."),
                    TaskFact("Your move", "**Try mute on your next call.**"),
                ]),
            ]))
            $0.changeSummary = "1 commit · 2 files · +64 −9"
            $0.buttons = [
                TaskButton(id: "merge", title: "Merge into main", shortcutHint: "⌘↩", style: .primary),
                TaskButton(id: "done", title: "Mark done", shortcutHint: "⌘D", style: .finish),
            ]
        }
        conversation.messages.append(KatanaMessage(.event("“Voice call mute design” is ready for review", status: .review, taskID: MockData.muteID)))
        say("Max, mute is ready for you to review: it stops me hearing you, and I keep talking. Want to see it?")
    }

    private func update(_ id: UUID, _ change: (inout TaskPage) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
    }

    private func later(_ seconds: Double, _ work: @escaping @MainActor (DemoStore) -> Void) {
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled else { return }
            work(self)
        }
        timers.append(task)
    }
}
