import SwiftUI

/// Colors, type and spacing for the whole shell.
///
/// The values are read off screenshots of the current Katana build, so they are
/// close, not exact. Swap them for Katana's own tokens where those exist.
public enum KatanaTheme {
    // MARK: Colors

    // A dark palette: the window frame and the sidebar on it are the darkest, with
    // the red glow; the panes are a step lighter. The first version of this shell
    // used slate-blue values instead.

    /// The window frame; the sidebar sits on it without a pane.
    public static let windowBackground = Color(katanaHex: 0x070709)
    /// Katana's pane and task pages, a step lighter than the frame.
    public static let paneBackground = Color(katanaHex: 0x111114)
    /// How solid the panes are. Below 1 the frame and its red glow show through.
    public static let paneOpacity: Double = 0.7
    public static let paneBorder = Color.white.opacity(0.06)
    /// Opaque surface for things that float over content, like a toast (`--card`).
    public static let card = Color(katanaHex: 0x131317)
    /// Selected tab, selected sidebar card (`--secondary`, `--glass-border`).
    public static let raised = Color.white.opacity(0.075)
    public static let raisedBorder = Color.white.opacity(0.085)
    /// The selected Katana card in the sidebar: darker than `raised`, so it sits
    /// quietly on the frame and its glow.
    public static let sidebarCard = Color.white.opacity(0.03)
    /// The user's chat bubbles, a step above `paneBackground`.
    public static let bubble = Color(katanaHex: 0x1B1B1F)
    public static let hover = Color.white.opacity(0.048)

    public static let textStrong = Color.white
    public static let textTitle = Color.white
    /// Body text: a soft white, so long passages don't glare; bold runs use `textStrong`.
    public static let textPrimary = Color(katanaHex: 0xDADADF)
    public static let textSecondary = Color(katanaHex: 0xBCBDC6)
    public static let textTertiary = Color(katanaHex: 0x95969E)
    /// Katana's older lines in her conversation; her newest stays `textPrimary`.
    public static let earlierText = Color(katanaHex: 0xB2B3BA)

    /// Red light falling from the top of the window frame across its full width,
    /// so it shows around the panes and behind the sidebar: `glow` at the top edge,
    /// fading out by `glowHeight` of the window (0 = top, 1 = bottom).
    public static let glow = Color(katanaHex: 0xE3342F, opacity: 0.11)
    public static let glowHeight: CGFloat = 0.38
    /// Where the glow is down to `glowMidStrength` of itself (0 = top): about 20%
    /// down. 0.30 was tried 7/11 (the red holds longer) and turned back.
    public static let glowMidpoint: CGFloat = glowHeight * 0.52
    public static let glowMidStrength: Double = 0.32

    /// The one red used for listening and the mic: the glow's hue, darker.
    public static let red = Color(katanaHex: 0xA62520)
    /// Behind red things that need a red surface, like the mic's pill.
    public static let redSurface = Color(katanaHex: 0x2B0C0B)

    /// Status colors. Each carries one meaning everywhere: the sidebar, status lines
    /// and Katana's event lines. Running is the lively one; finished is quiet.
    public static let finished = Color(katanaHex: 0x8E8F96)
    public static let working = Color(katanaHex: 0xC9CAD1)
    public static let needsYou = Color(katanaHex: 0xE8A23B)
    public static let failed = Color(katanaHex: 0xE5675F)
    /// "+212 −38" in a change summary.
    public static let diffAdded = Color(katanaHex: 0x5FC98A)
    public static let diffRemoved = failed
    /// Pane edge, dot and composer edge while Katana is listening: `red`, to match
    /// the mic's pill and the frame's glow (the original was teal #7CC6CF).
    public static let listening = red

    // MARK: Type

    public static let titleFont = Font.system(size: 16, weight: .semibold)
    public static let bodyFont = Font.system(size: 15)
    public static let monoFont = Font.system(size: 13, design: .monospaced)
    /// A task page's story (the agent's progress and report): a step smaller and
    /// in secondary text, so the outcome card under it reads first.
    public static let transcriptFont = Font.system(size: 13.5)
    /// "Why it was slow", "Status": a report bullet's bold lead-in, set as a small heading.
    public static let sectionLabelFont = Font.system(size: 13, weight: .semibold)
    public static let transcriptText = Color(katanaHex: 0xB0B1B9)
    /// The context Katana sent along with a message, under its bubble.
    public static let noteFont = Font.system(size: 12.5)
    public static let metaFont = Font.system(size: 13)
    public static let smallFont = Font.system(size: 12)
    public static let rowTitleFont = Font.system(size: 14, weight: .medium)
    public static let cardTitleFont = Font.system(size: 15, weight: .semibold)
    public static let headerLinkFont = Font.system(size: 14)
    public static let buttonFont = Font.system(size: 13.5, weight: .semibold)
    /// "At work", "Finished" over the sidebar's task groups.
    public static let groupLabelFont = Font.system(size: 11.5, weight: .semibold)
    /// The selected view tab's name: "Chat", "Page".
    public static let tabLabelFont = Font.system(size: 12.5, weight: .medium)

    // MARK: Buttons

    public static let buttonHeight: CGFloat = 32
    public static let buttonCornerRadius: CGFloat = 7
    public static let primaryButton = Color(katanaHex: 0xEDEDF0)
    public static let primaryButtonText = Color(katanaHex: 0x0E0E11)
    public static let secondaryButton = Color.white.opacity(0.05)
    /// The card that holds a task's outcome: "Your move", what changed and the buttons.
    public static let outcomeCard = Color.white.opacity(0.035)
    /// A task event's row in Katana's conversation.
    public static let eventFill = Color.white.opacity(0.025)

    // MARK: Window

    public static let windowPadding: CGFloat = 8
    public static let paneGap: CGFloat = 8
    public static let paneCornerRadius: CGFloat = 12
    public static let sidebarWidth: CGFloat = 316
    public static let sidebarAvatarSize: CGFloat = 44
    public static let sidebarAvatarScale: CGFloat = 1.35
    /// Katana's pane while a task page is open beside it. It shrinks toward
    /// `katanaPaneMinWidth` before the task page goes below `taskPaneMinWidth`.
    public static let katanaPaneWidth: CGFloat = 460
    public static let katanaPaneMinWidth: CGFloat = 360
    public static let taskPaneMinWidth: CGFloat = 420
    /// Narrowest window that fits all three panes.
    public static var workspaceMinWidth: CGFloat {
        windowPadding * 2 + sidebarWidth + paneGap * 2 + katanaPaneMinWidth + taskPaneMinWidth
    }

    // MARK: Pane header

    public static let headerHeight: CGFloat = 50
    public static let headerHorizontalPadding: CGFloat = 20
    /// The pane's view switcher: icon tabs in one shared track.
    public static let tabSize: CGFloat = 30
    public static let tabSpacing: CGFloat = 2
    public static let tabTrackPadding: CGFloat = 3
    public static let tabTrack = Color.white.opacity(0.03)
    public static let tabSelected = Color.white.opacity(0.11)
    /// The open task's row in the sidebar.
    public static let rowSelected = Color.white.opacity(0.07)

    // MARK: Text column

    /// Transcript, status row and composer share one centered column.
    public static let columnMaxWidth: CGFloat = 740
    public static let columnMinInset: CGFloat = 24
    /// Agent text wraps a bit before the column edge.
    public static let textMaxWidth: CGFloat = 650
    /// Body lines sit about 22 pt apart (15 pt type, 1.45x), tight enough to read
    /// as one paragraph; the gaps between paragraphs are clearly larger.
    public static let lineSpacing: CGFloat = 4
    public static let messageSpacing: CGFloat = 30
    /// Extra space above the agent's closing summary.
    public static let reportExtraTopSpacing: CGFloat = 14
    public static let paragraphSpacing: CGFloat = 16
    public static let bulletSpacing: CGFloat = 12
    public static let bulletIndent: CGFloat = 18

    // MARK: Katana pane

    public static let katanaInset: CGFloat = 36
    /// Katana's portrait in her pane's header, beside "Katana". Cropped like the
    /// sidebar's (`sidebarAvatarScale`), so the face fills it.
    public static let headerAvatarSize: CGFloat = 38
    public static let katanaMessageSpacing: CGFloat = 24
    /// The picture behind Katana's pane: just enough to sense it.
    public static let backdropOpacity: Double = 0.10
    public static let backdropBlur: CGFloat = 2
    /// Fully visible down to `backdropFadeStart`, gone by `backdropFadeEnd` (0 = top, 1 = bottom).
    public static let backdropFadeStart: CGFloat = 0.3
    public static let backdropFadeEnd: CGFloat = 0.85

    /// Scrolled text fades out over `topFade` under a pane's header, fully gone for
    /// the first `topFadeClear`, so no half-cut line shows at the edge.
    public static let topFade: CGFloat = 24
    public static let topFadeClear: CGFloat = 4

    // MARK: Scroll indicator (SubtleScrollView)

    public static let scrollThumb = Color.white.opacity(0.2)
    public static let scrollThumbWidth: CGFloat = 3
    /// Gap from the pane's right edge.
    public static let scrollThumbTrailing: CGFloat = 4
    /// Gap from the top and bottom of the scroll area.
    public static let scrollThumbInset: CGFloat = 6
    public static let scrollThumbMinLength: CGFloat = 28
    /// Kept short, so it reads as a position marker rather than a bar.
    public static let scrollThumbMaxLength: CGFloat = 60
    /// Seconds the indicator stays after scrolling stops.
    public static let scrollThumbLinger: Double = 1.2

    // MARK: Katana's mic (VoiceControl)

    /// Hit area of the mic, cancel and done icons.
    public static let voiceButtonSize: CGFloat = 36
    /// The red pill while listening. Its bars and edge scale with its height.
    public static let voicePillWidth: CGFloat = 52
    public static let voicePillHeight: CGFloat = 28
    public static let voiceSpacing: CGFloat = 8
    public static let voiceListeningFill = redSurface
    public static let voiceBars = red
    public static let voiceEdge = red
    /// Unfolding and folding back: stiff and without overshoot.
    public static let voiceSpring = Animation.interpolatingSpring(stiffness: 400, damping: 40)

    // MARK: Composer

    public static let composerMinHeight: CGFloat = 52
    public static let composerFill = Color.white.opacity(0.025)
    public static let sendButtonSize: CGFloat = 26
    public static let composerCornerRadius: CGFloat = 10
    public static let footerBottomPadding: CGFloat = 16
}

extension Color {
    /// `Color(katanaHex: 0x2C333E)`. Named so it won't clash with a `Color(hex:)` in the app.
    public init(katanaHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension View {
    /// Rounded pane with a hairline edge. Pass `highlight` to color the edge, e.g. while listening.
    public func katanaPane(highlight: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: KatanaTheme.paneCornerRadius, style: .continuous)
        return self
            .background(KatanaTheme.paneBackground.opacity(KatanaTheme.paneOpacity))
            .clipShape(shape)
            .overlay(shape.strokeBorder(highlight ?? KatanaTheme.paneBorder, lineWidth: highlight == nil ? 1 : 1.5))
            .animation(.easeOut(duration: 0.2), value: highlight == nil)
    }

    /// The window frame behind the panes: `windowBackground` with the red glow from the top.
    public func katanaWindowBackground() -> some View {
        background {
            ZStack {
                KatanaTheme.windowBackground
                FrameGlow()
            }
        }
    }
}
