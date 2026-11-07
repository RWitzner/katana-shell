import SwiftUI

/// A task's messages, top to bottom, then its change summary and buttons.
/// Text can be selected and copied.
struct TranscriptView: View {
    let messages: [TranscriptMessage]
    let changeSummary: String?
    let buttons: [TaskButton]
    let onButton: (String) -> Void
    /// Off when the page pins the outcome card above its composer instead.
    var showsOutcome = true

    var body: some View {
        let split = Self.splitOutcome(messages)
        VStack(alignment: .leading, spacing: KatanaTheme.messageSpacing) {
            ForEach(split.messages) { message in
                Group {
                    switch message.role {
                    case .agent:
                        BlocksView(blocks: message.blocks, font: KatanaTheme.transcriptFont, color: KatanaTheme.transcriptText)
                            .frame(maxWidth: KatanaTheme.textMaxWidth, alignment: .leading)
                    case .user:
                        UserBubble { BlocksView(blocks: message.blocks, font: KatanaTheme.transcriptFont) }
                    }
                }
                .padding(.top, message.isReport ? KatanaTheme.reportExtraTopSpacing : 0)
                .id(message.id)
            }

            if showsOutcome, split.facts != nil || changeSummary != nil || !buttons.isEmpty {
                OutcomeCard(facts: split.facts ?? [], changeSummary: changeSummary, buttons: buttons, onButton: onButton)
                    .padding(.top, -6)
                    .id("outcome")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    /// Takes the closing "You asked / Where it is / Your move" rows out of the
    /// last report, so they sit in the outcome card with what changed and the buttons.
    static func splitOutcome(_ messages: [TranscriptMessage]) -> (messages: [TranscriptMessage], facts: [TaskFact]?) {
        guard var last = messages.last, last.isReport, case .facts(let facts)? = last.blocks.last else {
            return (messages, nil)
        }
        last.blocks.removeLast()
        var rest = Array(messages.dropLast())
        if !last.blocks.isEmpty { rest.append(last) }
        return (rest, facts)
    }
}

/// The task's outcome in one card: its status, where it stands, what changed,
/// and the buttons. A task page pins it above the composer.
struct OutcomeCard: View {
    let facts: [TaskFact]
    let changeSummary: String?
    let buttons: [TaskButton]
    let onButton: (String) -> Void
    var status: TaskStatus? = nil
    var since: Date? = nil

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        VStack(alignment: .leading, spacing: 14) {
            if let status, let since {
                TaskStatusRow(status: status, since: since)
                    .padding(.leading, -8)
            }
            if !facts.isEmpty {
                FactsView(facts: facts)
            }
            if changeSummary != nil || !buttons.isEmpty {
                if !facts.isEmpty {
                    Rectangle().fill(KatanaTheme.paneBorder).frame(height: 1)
                }
                if let changeSummary {
                    ChangeSummaryText(summary: changeSummary)
                }
                if !buttons.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(buttons.filter { $0.style != .finish }) { button in
                            switch button.style {
                            case .primary:
                                PrimaryButton(title: button.title, shortcutHint: button.shortcutHint) { onButton(button.id) }
                            default:
                                SecondaryButton(title: button.title, shortcutHint: button.shortcutHint) { onButton(button.id) }
                            }
                        }
                        Spacer(minLength: 8)
                        ForEach(buttons.filter { $0.style == .finish }) { button in
                            GhostButton(title: button.title, shortcutHint: button.shortcutHint) { onButton(button.id) }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(KatanaTheme.outcomeCard))
        .overlay(shape.strokeBorder(KatanaTheme.paneBorder, lineWidth: 1))
    }
}

/// Right-aligned rounded bubble for what the user said.
struct UserBubble<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 48)
            content
                .padding(.horizontal, 17)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(KatanaTheme.bubble))
        }
    }
}

struct BlocksView: View {
    let blocks: [TranscriptBlock]
    var font: Font = KatanaTheme.bodyFont
    var color: Color = KatanaTheme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: KatanaTheme.paragraphSpacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let markdown):
                    InlineText(markdown, font: font, color: color)
                case .bullets(let items):
                    BulletList(items: items, font: font, color: color)
                case .facts(let facts):
                    FactsView(facts: facts)
                }
            }
        }
    }
}

private struct BulletList: View {
    let items: [String]
    var font: Font = KatanaTheme.bodyFont
    var color: Color = KatanaTheme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: KatanaTheme.bulletSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                if let section = Self.section(item) {
                    // "**Status:** works only…" reads as a small labeled section whose
                    // first sentence, its conclusion, is a step brighter.
                    VStack(alignment: .leading, spacing: 5) {
                        Text(section.label)
                            .font(KatanaTheme.sectionLabelFont)
                            .foregroundStyle(KatanaTheme.textTitle)
                        InlineText(Self.leadBrighter(section.body), font: font, color: color)
                    }
                    .padding(.top, 12)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("•")
                            .font(font)
                            .foregroundStyle(KatanaTheme.textSecondary)
                            .frame(width: KatanaTheme.bulletIndent, alignment: .leading)
                        InlineText(item, font: font, color: color)
                    }
                }
            }
        }
    }

    /// Splits "**Label:** body" into its label and body; nil for other bullets.
    static func section(_ item: String) -> (label: String, body: String)? {
        guard item.hasPrefix("**"), let close = item.range(of: ":**") else { return nil }
        let label = String(item[item.index(item.startIndex, offsetBy: 2)..<close.lowerBound])
        guard !label.isEmpty, !label.contains("**") else { return nil }
        let body = item[close.upperBound...].trimmingCharacters(in: .whitespaces)
        return (label, body.prefix(1).uppercased() + body.dropFirst())
    }

    /// Bolds the first sentence of a section body, so its conclusion reads first.
    static func leadBrighter(_ body: String) -> String {
        guard !body.contains("**"), let end = body.range(of: ". ") else { return body }
        let lead = body[..<end.lowerBound]
        let rest = body[end.upperBound...]
        return "**\(lead).** \(rest)"
    }
}

/// "You asked / Where it is / Your move" rows.
private struct FactsView: View {
    let facts: [TaskFact]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(fact.label)
                        .font(KatanaTheme.smallFont)
                        .foregroundStyle(KatanaTheme.textSecondary)
                        .frame(width: 92, alignment: .leading)
                    InlineText(fact.value, detail: fact.detail)
                }
            }
        }
    }
}

/// One paragraph of inline Markdown. Bold runs are brighter than the body text.
struct InlineText: View {
    let markdown: String
    var detail: String? = nil
    var font: Font = KatanaTheme.bodyFont
    var color: Color = KatanaTheme.textPrimary

    init(_ markdown: String, detail: String? = nil, font: Font = KatanaTheme.bodyFont, color: Color = KatanaTheme.textPrimary) {
        self.markdown = markdown
        self.detail = detail
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(Self.attributed(markdown, detail: detail))
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(KatanaTheme.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    static func attributed(_ markdown: String, detail: String? = nil) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var text = (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
        let runs = text.runs.map { ($0.range, $0.inlinePresentationIntent) }
        for (range, intent) in runs {
            guard let intent else { continue }
            if intent.contains(.stronglyEmphasized) {
                text[range].foregroundColor = KatanaTheme.textStrong
            }
            if intent.contains(.code) {
                text[range].font = KatanaTheme.monoFont
                text[range].foregroundColor = KatanaTheme.textSecondary
            }
        }
        if let detail {
            var suffix = AttributedString(" · \(detail)")
            suffix.foregroundColor = KatanaTheme.textSecondary
            suffix.font = KatanaTheme.metaFont
            text += suffix
        }
        return text
    }
}

/// "1 commit · 4 files · +212 −38" with the added lines green and the removed ones red.
struct ChangeSummaryText: View {
    let summary: String

    var body: some View {
        Text(Self.attributed(summary))
            .font(KatanaTheme.smallFont)
            .foregroundStyle(KatanaTheme.textSecondary)
    }

    static func attributed(_ summary: String) -> AttributedString {
        var text = AttributedString()
        let words = summary.split(separator: " ", omittingEmptySubsequences: false)
        for (index, word) in words.enumerated() {
            var part = AttributedString(String(word))
            let digits = word.dropFirst()
            if !digits.isEmpty, digits.allSatisfy(\.isNumber) {
                if word.hasPrefix("+") { part.foregroundColor = KatanaTheme.diffAdded }
                if word.hasPrefix("−") || word.hasPrefix("-") { part.foregroundColor = KatanaTheme.diffRemoved }
            }
            text += part
            if index < words.count - 1 { text += AttributedString(" ") }
        }
        return text
    }
}
