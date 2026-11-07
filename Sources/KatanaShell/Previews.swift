import SwiftUI

#if DEBUG
extension TaskPage {
    static let preview = TaskPage(
        title: "Fast and safe voice hang-up",
        summary: "On investigate-improve-delay-when",
        status: .finished,
        statusSince: Date().addingTimeInterval(-4 * 60),
        agentName: "Claude",
        modelLabel: "Opus 5.5 · high effort · claude1",
        hasBrowser: true,
        messages: [
            .user("Make hang-ups faster without hanging up on things I didn’t mean."),
            .agent("Now the edits to her brief, the `live.rs` docs and the PLAN decision."),
            TranscriptMessage(isReport: true, blocks: [
                .paragraph("**Ending a call: built. A plain “you can end the call” now hangs up about 1.5 s after you stop talking.**"),
                .bullets(["**Status:** committed and pushed on this task’s branch, not merged."]),
                .facts([
                    TaskFact("You asked", "Make hang-ups faster and safe.", detail: "12m ago"),
                    TaskFact("Your move", "**Merge it, then restart the daemon.**"),
                ]),
            ]),
        ],
        changeSummary: "1 commit · 4 files · +212 −38",
        buttons: [
            TaskButton(id: "merge", title: "Merge into main", shortcutHint: "⌘↩", style: .primary),
            TaskButton(id: "done", title: "Mark done", shortcutHint: "⌘D", style: .finish),
        ]
    )
}

extension KatanaConversation {
    static let preview = KatanaConversation(
        messages: [
            KatanaMessage(.katana("Exactly. Your Mac handles listening and speaking locally, while `GPT-6.1-Terra` handles the thinking.")),
            KatanaMessage(.event("“Wake word on livestream” finished", status: .finished)),
            KatanaMessage(.user("Are you ready?", notes: ["Beside you: Fast and safe voice hang-up, a task's page."])),
        ],
        isThinking: true,
        modelLabel: "GPT-6.1-Terra · low effort · max.blade.hansen account"
    )
}

#Preview("Workspace") {
    KatanaWorkspaceView(
        tasks: [TaskPage.preview],
        selection: .katana,
        besideTaskID: TaskPage.preview.id,
        conversation: .preview,
        footer: WorkspaceFooter(usage: 0.24, usageLabel: "wk 24% used")
    )
    .frame(width: 1500, height: 900)
}

#Preview("Task page") {
    TaskPageView(page: .preview)
        .katanaPane()
        .frame(width: 900, height: 760)
}
#endif
