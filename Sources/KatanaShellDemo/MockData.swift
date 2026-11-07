import Foundation
import KatanaShell

/// Content modeled on screenshots of Katana, so the shell looks like a real day.
/// Lines the screenshots did not show are made up.
enum MockData {
    static let hangUpID = UUID()
    static let muteID = UUID()

    static let footer = WorkspaceFooter(
        devBuildLine: "main @ 633e0c95 · Preserve macOS paste on new tasks",
        usage: 0.24,
        usageLabel: "wk 24% used"
    )

    static func conversation() -> KatanaConversation {
        KatanaConversation(
            messages: [
                KatanaMessage(.katana("Exactly. Your Mac handles listening and speaking locally, while `GPT-6.1-Terra` handles the thinking and tools. That gives you a fast, capable assistant without paying a separate voice API charge for every conversation.")),
                KatanaMessage(.event("“Wake word on livestream” finished", status: .finished)),
                KatanaMessage(.katana("Max, “Fast and safe voice hang-up” is ready for you to review. A plain “you can end the call” now hangs up about 1.5 s after you stop talking. Want to see its findings?")),
                KatanaMessage(.user(
                    "Are you ready? Are you running in fast mode today?",
                    notes: [
                        "Beside you: Fast and safe voice hang-up, a task’s page.",
                        "Heard on the mic you opened for their answer to your news: they haven’t tapped Talk or said your name since. They may be talking to someone else.",
                        "They cut your last answer off: they heard only “The fast”.",
                    ]
                )),
            ],
            isThinking: true,
            modelLabel: "GPT-6.1-Terra · low effort · max.blade.hansen account"
        )
    }

    static func tasks() -> [TaskPage] {
        [
            TaskPage(
                id: muteID,
                title: "Voice call mute design",
                summary: "Confirm every daemon test suite passed before merging",
                status: .working,
                statusSince: Date().addingTimeInterval(-11 * 60),
                agentName: "Claude",
                modelLabel: "Opus 5.5 · high effort · claude1",
                messages: [
                    .user("Design mute for voice calls: when I mute, Katana stops hearing me but keeps talking."),
                    .agent("Reading how the call loop handles the mic today."),
                    .agent("Muted speech still reaches the turn path. Moving the mute check in front of it."),
                    .agent("Got a note from the hang-up task: keep muted speech off the turn path. That matches the plan."),
                    .agent("Running every daemon test suite before I merge."),
                ]
            ),
            TaskPage(
                title: "UI visual directions",
                summary: "1 helper · 1 job · Half the renders are done",
                status: .working,
                statusSince: Date().addingTimeInterval(-6 * 60),
                agentName: "Claude",
                modelLabel: "Fable 5.5 · high effort · claude1",
                hasBrowser: true,
                messages: [
                    .user("Make four visual directions for Katana’s window and show them side by side."),
                    .agent("Started a helper to render the directions while I write the notes."),
                    .agent("Two of four renders are done: “Nightglass” and “Paper”. The gallery is open in this task’s browser."),
                ]
            ),
            TaskPage(
                title: "This does not seem like a good idea",
                summary: "Maximilian’s MacBook Pro · On not-seem-like-a-good-idea",
                status: .finished,
                statusSince: Date().addingTimeInterval(-52 * 60),
                agentName: "Codex",
                modelLabel: "GPT-6.1-Sol · medium effort · maxblade",
                messages: [
                    .user("Should Katana answer the phone when I’m not at the desk?"),
                    TranscriptMessage(isReport: true, blocks: [
                        .paragraph("**Not yet. Without you at the desk, Katana can’t tell a real caller from a recording.**"),
                        .facts([
                            TaskFact("You asked", "Should Katana answer the phone when you’re away?", detail: "1h ago"),
                            TaskFact("Your move", "**Leave it off for now.**"),
                        ]),
                    ]),
                ],
                buttons: [TaskButton(id: "done", title: "Mark done", shortcutHint: "⌘D", style: .finish)]
            ),
            TaskPage(
                title: "Land Mouse current disconnect",
                status: .finished,
                statusSince: Date().addingTimeInterval(-2 * 3600),
                agentName: "Claude",
                modelLabel: "Sonnet 5.5 · medium effort · claude1",
                messages: [
                    .user("The Mouse keeps disconnecting mid-session. Land the fix from yesterday."),
                    TranscriptMessage(isReport: true, blocks: [
                        .paragraph("**Landed. The Mouse reconnects on its own and keeps the session.**"),
                    ]),
                ],
                changeSummary: "Merged · 2 commits · 5 files · +96 −41",
                buttons: [TaskButton(id: "done", title: "Mark done", shortcutHint: "⌘D", style: .finish)]
            ),
            hangUp(),
        ]
    }

    static func hangUp() -> TaskPage {
        TaskPage(
            id: hangUpID,
            title: "Fast and safe voice hang-up",
            summary: "On investigate-improve-delay-when",
            status: .review,
            statusSince: Date().addingTimeInterval(-4 * 60),
            agentName: "Claude",
            modelLabel: "Opus 5.5 · high effort · claude1",
            hasBrowser: true,
            messages: [
                .user("Hang-ups are too slow. When I say “you can end the call” it should hang up right away, without hanging up on things I didn’t mean. Investigate, improve, and tell me when it’s in."),
                .agent("Reading the hang-up path in the daemon first, then the call logs since October."),
                .agent("Found it: the hang-up waits for Katana’s spoken reply before it closes the call. Measuring how long that wait is on real calls."),
                .agent("Gate verified. Now updating the docs and her brief that said the daemon never hangs up on words itself."),
                .agent("Now the edits to her brief, the `live.rs` docs and the PLAN decision."),
                .agent("Log lookup is shared across parallel tests by call id; giving my test its own id."),
                .agent("All 625+ tests pass, clippy clean. Re-running the log replay after the last tweak, then committing."),
                .agent("Sending the mute task a short coordination note so its build keeps muted speech off the turn path."),
                TranscriptMessage(isReport: true, blocks: [
                    .paragraph("**Ending a call: built. A plain “you can end the call” now hangs up about 1.5 s after you stop talking, without waiting for Katana’s reply.**"),
                    .bullets([
                        "**Why it was slow:** in 92 hang-ups since October, the wait for Katana’s reply was 2.5 s typically and up to 32 s. Today at 10:56, “You’re the goat. You can end this call.” never ended the call.",
                        "**Real-call check:** across 438 of your real turns, it caught 49 of the 92 hang-ups and never matched anything else. Anything unclear still goes to Katana: questions, quotes, “after you do that”, “don’t”, mute, “go to sleep” and “bye”. Zero false hang-ups can’t be guaranteed: a plain “you can end the call” said to someone else, or read word for word from chat, would still hang up.",
                        "**Status:** works only with the “On this Mac” voice, not GPT-Live or Gemini. Tests pass. It’s committed and pushed on this task’s branch, not merged, and the running app and live daemon still use the old build.",
                    ]),
                    .facts([
                        TaskFact("You asked", "Make “you can end the call” hang up fast, without false hang-ups.", detail: "14m ago"),
                        TaskFact("Where it is", "Built and tested on its branch; not merged, not live."),
                        TaskFact("Your move", "**Merge it, then restart the daemon.**"),
                    ]),
                ]),
            ],
            changeSummary: "1 commit · 4 files · +212 −38",
            buttons: [
                TaskButton(id: "merge", title: "Merge into main", shortcutHint: "⌘↩", style: .primary),
                TaskButton(id: "pr", title: "Pull request"),
                TaskButton(id: "done", title: "Mark done", shortcutHint: "⌘D", style: .finish),
            ]
        )
    }

    static let terminalLines = """
    ~/katana (investigate-improve-delay-when) $ cargo test -p daemon
       Compiling daemon v0.9.0 (/Users/max/katana/daemon)
        Finished `test` profile [unoptimized + debuginfo] target(s) in 41.20s
         Running unittests src/lib.rs (target/debug/deps/daemon-3f9c1a7e)

    running 628 tests
    test live::hangup::plain_phrase_ends_call ... ok
    test live::hangup::ignores_quoted_phrase ... ok
    test live::hangup::waits_for_silence_1500ms ... ok
    ...
    test result: ok. 625 passed; 0 failed; 3 ignored; finished in 12.84s

    ~/katana (investigate-improve-delay-when) $ git push -u origin investigate-improve-delay-when
     * [new branch]      investigate-improve-delay-when -> investigate-improve-delay-when
    ~/katana (investigate-improve-delay-when) $
    """
}
