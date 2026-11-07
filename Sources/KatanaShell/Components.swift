import SwiftUI

// MARK: - Pane header tabs

/// The icons used in pane headers.
public enum PaneIcon: Hashable, Sendable {
    case page, person, globe, terminal

    var help: String {
        switch self {
        case .page: "Page"
        case .person: "Chat"
        case .globe: "Browser"
        case .terminal: "Terminal"
        }
    }

    /// Shown beside the icon on the selected tab.
    var title: String {
        switch self {
        case .page: "Page"
        case .person: "Chat"
        case .globe: "Browser"
        case .terminal: "Terminal"
        }
    }
}

struct PaneIconView: View {
    let icon: PaneIcon

    var body: some View {
        switch icon {
        case .page: Image(systemName: "doc.plaintext").font(.system(size: 13.5))
        case .person: Image(systemName: "bubble.left").font(.system(size: 13.5))
        case .globe: Image(systemName: "globe").font(.system(size: 14.5))
        case .terminal: Text(">_").font(.system(size: 13.5, weight: .medium, design: .monospaced))
        }
    }
}

/// A pane's view switcher: its icon tabs in one track, so it reads as one control.
/// `quiet` drops the track and the name: bare icons, for Katana's own pane, so it
/// doesn't read as a twin of the task page's switcher beside it.
struct PaneTabs<Tab: Hashable>: View {
    let tabs: [Tab]
    let selection: Tab
    let icon: (Tab) -> PaneIcon
    var quiet = false
    let select: (Tab) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        HStack(spacing: KatanaTheme.tabSpacing) {
            ForEach(tabs, id: \.self) { item in
                PaneTabButton(icon: icon(item), isSelected: selection == item, showsTitle: !quiet) { select(item) }
            }
        }
        .padding(KatanaTheme.tabTrackPadding)
        .background(shape.fill(quiet ? .clear : KatanaTheme.tabTrack))
        .overlay(shape.strokeBorder(quiet ? .clear : KatanaTheme.paneBorder, lineWidth: 1))
    }
}

/// A square icon button; the selected one gets a raised box.
struct PaneTabButton: View {
    let icon: PaneIcon
    let isSelected: Bool
    var showsTitle = true
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        Button(action: action) {
            HStack(spacing: 6) {
                PaneIconView(icon: icon)
                if isSelected, showsTitle {
                    Text(icon.title).font(KatanaTheme.tabLabelFont)
                }
            }
                .foregroundStyle(isSelected || hovering ? KatanaTheme.textTitle : KatanaTheme.textSecondary)
                .padding(.horizontal, isSelected && showsTitle ? 9 : 0)
                .frame(minWidth: KatanaTheme.tabSize, minHeight: KatanaTheme.tabSize, maxHeight: KatanaTheme.tabSize)
                .background(shape.fill(isSelected ? KatanaTheme.tabSelected : (hovering ? KatanaTheme.hover : .clear)))
                .overlay(shape.strokeBorder(isSelected ? KatanaTheme.raisedBorder : .clear, lineWidth: 1))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(icon.help)
        .accessibilityLabel(icon.help)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Small buttons

// One button family: a filled primary for the next step, a quiet raised
// secondary beside it, and a bare ghost for header actions like "Go to it".

/// Bare text button for headers and dialogs: "Go to it", "Cancel esc".
struct GhostButton: View {
    let title: String
    var shortcutHint: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).font(KatanaTheme.headerLinkFont)
                if let shortcutHint {
                    Text(shortcutHint).font(.system(size: 11)).foregroundStyle(KatanaTheme.textTertiary)
                }
            }
            .foregroundStyle(hovering ? KatanaTheme.textTitle : KatanaTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(hovering ? KatanaTheme.hover : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Filled button for the one main next step: "Merge into main ⌘↩".
struct PrimaryButton: View {
    let title: String
    var shortcutHint: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KatanaTheme.buttonCornerRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title).font(KatanaTheme.buttonFont)
                if let shortcutHint {
                    Text(shortcutHint).font(.system(size: 11)).opacity(0.55)
                }
            }
            .foregroundStyle(KatanaTheme.primaryButtonText)
            .padding(.horizontal, 14)
            .frame(height: KatanaTheme.buttonHeight)
            .background(shape.fill(hovering ? Color.white : KatanaTheme.primaryButton))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Raised button for the other choices beside the primary: "Pull request", "Done ⌘D".
struct SecondaryButton: View {
    let title: String
    var shortcutHint: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KatanaTheme.buttonCornerRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title).font(KatanaTheme.buttonFont).foregroundStyle(KatanaTheme.textTitle)
                if let shortcutHint {
                    Text(shortcutHint).font(.system(size: 11)).foregroundStyle(KatanaTheme.textTertiary)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: KatanaTheme.buttonHeight)
            .background(shape.fill(hovering ? KatanaTheme.raised : KatanaTheme.secondaryButton))
            .overlay(shape.strokeBorder(KatanaTheme.raisedBorder, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        HeaderIconButton(systemImage: "xmark", label: "Close", action: action)
    }
}

/// A bare icon in a pane header, with a tooltip: "Go to it", "Close".
struct HeaderIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13.5))
                .foregroundStyle(hovering ? KatanaTheme.textTitle : KatanaTheme.textSecondary)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(hovering ? KatanaTheme.hover : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(label)
        .accessibilityLabel(label)
    }
}

// MARK: - Status dot

/// A turning arc while working, an amber dot when it needs you (a question, or a
/// result ready for review), a quiet gray check when finished, a red cross when it failed.
struct StatusDot: View {
    let status: TaskStatus
    var size: CGFloat = 11
    /// Kept for callers; the working arc always spins.
    var pulses = false

    var body: some View {
        Group {
            switch status {
            case .finished:
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.95, weight: .bold))
                    .foregroundStyle(KatanaTheme.finished)
            case .working:
                WorkingArc(lineWidth: max(1.5, size * 0.16))
            case .needsYou:
                Circle().fill(KatanaTheme.needsYou).padding(size * 0.08)
            case .review:
                Circle().fill(KatanaTheme.needsYou).padding(size * 0.08)
            case .failed:
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.9, weight: .bold))
                    .foregroundStyle(KatanaTheme.failed)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(status.label)
    }
}

/// Three quarters of a ring, turning.
private struct WorkingArc: View {
    let lineWidth: CGFloat
    @State private var turning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(KatanaTheme.working, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(turning ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { turning = true }
            }
    }
}

/// "4m", "2h", "3d" since a date: for the sidebar's right edge.
enum RelativeAge {
    static func short(since date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86_400: return "\(seconds / 3600)h"
        default: return "\(seconds / 86_400)d"
        }
    }
}

// MARK: - Composer

/// The message box: what you write on top; the model, an optional key hint, the
/// mic and send along the bottom. Return sends. Pass `voice` for Katana's mic,
/// which unfolds while listening (`VoiceControl`); without it the mic is a plain toggle.
struct KatanaComposer: View {
    let placeholder: String
    var hint: String? = nil
    /// "Opus 5.5 · high effort · claude1". The account shows on hover only.
    var modelLabel: String? = nil
    /// With it, the model label is a menu for picking the effort.
    var onEffort: ((String) -> Void)? = nil
    let isListening: Bool
    let onSend: (String) -> Void
    let onMicToggle: () -> Void
    var voice: VoiceActions? = nil

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: KatanaTheme.composerCornerRadius, style: .continuous)
        VStack(alignment: .leading, spacing: 6) {
            TextField(
                "",
                text: $text,
                prompt: Text(isListening ? "Listening…" : placeholder).foregroundStyle(KatanaTheme.textTertiary),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(KatanaTheme.bodyFont)
            .foregroundStyle(KatanaTheme.textPrimary)
            .lineLimit(1...6)
            .focused($focused)
            .onSubmit(send)
            .padding(.horizontal, 4)

            HStack(spacing: 6) {
                if let modelLabel {
                    ModelMenu(label: modelLabel, onEffort: onEffort)
                }
                Spacer(minLength: 8)
                if let hint, !isListening {
                    HStack(spacing: 5) {
                        KeyCap(text: hint)
                        Text("to talk")
                            .font(KatanaTheme.smallFont)
                            .foregroundStyle(KatanaTheme.textTertiary)
                    }
                    .help("Press \(hint) to talk")
                    .padding(.trailing, 4)
                }
                // Both mics sit in the same round pill while idle.
                Group {
                    if let voice {
                        VoiceControl(isListening: isListening, actions: voice)
                    } else {
                        MicButton(isListening: isListening, action: onMicToggle)
                    }
                }
                .background(Capsule().fill(isListening ? .clear : KatanaTheme.secondaryButton))
                .overlay(Capsule().strokeBorder(isListening ? .clear : KatanaTheme.paneBorder, lineWidth: 1))
                if !(isListening && voice != nil) {
                    SendButton(isEnabled: !trimmed.isEmpty, action: send)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.top, 13)
        .padding(.bottom, 8)
        .frame(minHeight: KatanaTheme.composerMinHeight)
        .background(shape.fill(KatanaTheme.composerFill))
        .overlay(shape.strokeBorder(borderColor, lineWidth: isListening && voice == nil ? 1.5 : 1))
        .contentShape(shape)
        .onTapGesture { focused = true }
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var borderColor: Color {
        // With the unfolding mic, the red pill shows that Katana listens.
        if isListening, voice == nil { return KatanaTheme.listening }
        return focused ? KatanaTheme.raisedBorder : KatanaTheme.paneBorder
    }

    private func send() {
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}

/// The model in the composer. With `onEffort` it is a menu for the effort, with
/// a chevron; without, a plain label. The account shows on hover.
private struct ModelMenu: View {
    let label: String
    let onEffort: ((String) -> Void)?

    static let efforts = ["low", "medium", "high"]

    var body: some View {
        if let onEffort {
            Menu {
                ForEach(Self.efforts, id: \.self) { effort in
                    Button("\(effort.prefix(1).uppercased() + effort.dropFirst()) effort") { onEffort(effort) }
                }
            } label: {
                // One Text, chevron included, so the menu keeps it after the label.
                (Text(ModelLabel.attributed(label, showsAccount: false))
                    + Text("  ")
                    + Text(Image(systemName: "chevron.down"))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(KatanaTheme.textTertiary))
                    .font(KatanaTheme.smallFont)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(label)
            .accessibilityLabel("Model: \(label)")
            .padding(.leading, 4)
        } else {
            ModelLabel(text: label, showsAccount: false)
                .help(label)
                .padding(.leading, 4)
        }
    }
}

/// A key drawn as a key: "space" beside the mic.
private struct KeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(KatanaTheme.textTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(KatanaTheme.raisedBorder, lineWidth: 1))
    }
}

/// Round send button: bright once there is something to send.
private struct SendButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(isEnabled ? KatanaTheme.primaryButtonText : KatanaTheme.textSecondary)
                .frame(width: KatanaTheme.sendButtonSize, height: KatanaTheme.sendButtonSize)
                .background(Circle().fill(isEnabled ? KatanaTheme.primaryButton : KatanaTheme.raised))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help("Send (↩)")
        .accessibilityLabel("Send")
    }
}

private struct MicButton: View {
    let isListening: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.system(size: 16))
                .foregroundStyle(isListening ? KatanaTheme.listening : (hovering ? KatanaTheme.textTitle : KatanaTheme.textSecondary))
                .frame(width: KatanaTheme.voiceButtonSize, height: KatanaTheme.voiceButtonSize)
                .background(
                    Capsule()
                        .fill(isListening ? KatanaTheme.listening.opacity(0.14) : (hovering ? KatanaTheme.hover : .clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(isListening ? "Stop listening" : "Talk")
        .accessibilityLabel(isListening ? "Stop listening" : "Talk")
    }
}

// MARK: - Model label

/// "Opus 5.5 · high effort · claude1": the model in secondary text, the rest quieter.
struct ModelLabel: View {
    let text: String
    /// Without it, a third part (the account) is left out.
    var showsAccount = true

    var body: some View {
        Text(Self.attributed(text, showsAccount: showsAccount))
            .font(KatanaTheme.smallFont)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    static func attributed(_ text: String, showsAccount: Bool = true) -> AttributedString {
        var parts = text.components(separatedBy: " · ")
        if !showsAccount, parts.count > 2 { parts.removeLast() }
        var model = AttributedString(parts[0])
        model.foregroundColor = KatanaTheme.textSecondary
        guard parts.count > 1 else { return model }
        var rest = AttributedString(" · " + parts.dropFirst().joined(separator: " · "))
        rest.foregroundColor = KatanaTheme.textTertiary
        return model + rest
    }
}

// MARK: - Layout helpers

/// One centered column, at most `columnMaxWidth` wide.
struct ColumnLayout: ViewModifier {
    var inset: CGFloat = KatanaTheme.columnMinInset

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: KatanaTheme.columnMaxWidth, alignment: .leading)
            .padding(.horizontal, inset)
            .frame(maxWidth: .infinity)
    }
}

/// Fades a scroll view's content out at its top and bottom edges.
struct EdgeFade: ViewModifier {
    var top: CGFloat = 0
    /// Fully hidden band above the top fade.
    var topClear: CGFloat = 0
    var bottom: CGFloat = 0

    func body(content: Content) -> some View {
        content.mask(
            VStack(spacing: 0) {
                Color.clear.frame(height: topClear)
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: top)
                Rectangle().fill(.black)
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: bottom)
            }
        )
    }
}

/// Stand-in for a browser view.
public struct BrowserPlaceholder: View {
    let caption: String

    public init(caption: String = "The browser goes here") {
        self.caption = caption
    }

    public var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe").font(.system(size: 28))
            Text(caption).font(KatanaTheme.bodyFont)
        }
        .foregroundStyle(KatanaTheme.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Stand-in for a terminal view.
public struct TerminalPlaceholder: View {
    let caption: String

    public init(caption: String = "The terminal goes here") {
        self.caption = caption
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text(">_").font(.system(size: 26, weight: .medium, design: .monospaced))
            Text(caption).font(KatanaTheme.bodyFont)
        }
        .foregroundStyle(KatanaTheme.textTertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Red light falling from the window's top edge across its full width: full
/// `glow` at the top, a third of it at `glowMidpoint`, nothing at `glowHeight`. It lies
/// on the window frame, so it shows behind the sidebar and around the panes.
struct FrameGlow: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: KatanaTheme.glow, location: 0),
                .init(color: KatanaTheme.glow.opacity(KatanaTheme.glowMidStrength), location: KatanaTheme.glowMidpoint),
                .init(color: KatanaTheme.glow.opacity(0), location: KatanaTheme.glowHeight),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
