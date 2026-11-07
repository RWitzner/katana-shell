import SwiftUI

/// What Katana's mic asks for: start listening, drop what was heard, or finish and send it.
struct VoiceActions {
    var start: () -> Void
    var cancel: () -> Void
    var finish: () -> Void
}

/// The mic in Katana's composer. Idle, it is a bare mic icon. While Katana
/// listens it unfolds into a red pill with moving level bars and a red edge
/// running around it, with a bare cancel icon sliding out to its left and a done
/// icon to its right. Folding back plays the same motion in reverse.
///
/// The bars are a stand-in: drive them from the real input level in Katana.
struct VoiceControl: View {
    let isListening: Bool
    let actions: VoiceActions

    var body: some View {
        HStack(spacing: KatanaTheme.voiceSpacing) {
            if isListening {
                VoiceSideButton(systemImage: "xmark", label: "Cancel", action: actions.cancel)
                    .transition(.tucked(x: tuck))
            }
            pill
                .zIndex(1)
            if isListening {
                VoiceSideButton(systemImage: "checkmark", label: "Done", action: actions.finish)
                    .transition(.tucked(x: -tuck))
            }
        }
        .animation(KatanaTheme.voiceSpring, value: isListening)
    }

    /// How far the side buttons travel: from behind the pill to their place.
    private var tuck: CGFloat { KatanaTheme.voiceButtonSize + KatanaTheme.voiceSpacing }

    private var pill: some View {
        // While listening, cancel and done are the way out; the pill only shows it.
        // (Not `.disabled`: that would dim the bars.)
        Button(action: { if !isListening { actions.start() } }) {
            ZStack {
                Capsule()
                    .fill(isListening ? KatanaTheme.voiceListeningFill : Color.clear)
                if isListening {
                    RunningEdge()
                        .transition(.blurFade)
                    LevelBars()
                        .transition(.blurFade)
                } else {
                    Image(systemName: "mic")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(KatanaTheme.textTitle)
                        .transition(.blurFade)
                }
            }
            .frame(
                width: isListening ? KatanaTheme.voicePillWidth : KatanaTheme.voiceButtonSize,
                height: isListening ? KatanaTheme.voicePillHeight : KatanaTheme.voiceButtonSize
            )
            .contentShape(Capsule())
            .frame(height: KatanaTheme.voiceButtonSize)
        }
        .buttonStyle(.plain)
        .help(isListening ? "Listening" : "Talk")
        .accessibilityLabel(isListening ? "Listening" : "Talk")
    }
}

/// Cancel and done: bare icons beside the pill, with a full-size hit area.
private struct VoiceSideButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(KatanaTheme.textTitle)
                .frame(width: KatanaTheme.voiceButtonSize, height: KatanaTheme.voiceButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

/// Pill sizes below are drawn for a 36 pt pill and scaled to `voicePillHeight`.
private let pillScale = KatanaTheme.voicePillHeight / 36

/// Six red bars, each moving through its own heights once a second, a little after the one before.
private struct LevelBars: View {
    private static let count = 6
    private static let period = 1.0
    private static let stagger = 0.08

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2.5 * pillScale) {
                ForEach(0..<Self.count, id: \.self) { bar in
                    Capsule()
                        .fill(KatanaTheme.voiceBars)
                        .frame(width: 3 * pillScale, height: Self.height(bar: bar, time: time))
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Heights in points, a fixed set per bar (low, high, middle, highest, low).
    private static let keyframes: [[CGFloat]] = (0..<count).map { bar in
        let ranges: [(CGFloat, CGFloat)] = [(4.5, 3.5), (10, 5.5), (6.5, 4.5), (13.5, 6.5), (5.5, 3.5)]
        return ranges.enumerated().map { step, range in (range.0 + range.1 * unitNoise(bar, step)) * pillScale }
    }

    private static func height(bar: Int, time: TimeInterval) -> CGFloat {
        let frames = keyframes[bar]
        let progress = ((time - Double(bar) * stagger) / period).truncatingRemainder(dividingBy: 1)
        let position = (progress < 0 ? progress + 1 : progress) * Double(frames.count)
        let index = Int(position) % frames.count
        let next = (index + 1) % frames.count
        let fraction = CGFloat(position - floor(position))
        return frames[index] + (frames[next] - frames[index]) * fraction
    }

    /// A stable 0...1 value per bar and step, so the bars look random but never jump between launches.
    private static func unitNoise(_ a: Int, _ b: Int) -> CGFloat {
        var h = UInt32(truncatingIfNeeded: (a &+ 1) &* 73_856_093 ^ (b &+ 1) &* 19_349_663)
        h ^= h >> 13
        h = h &* 1_274_126_177
        h ^= h >> 16
        return CGFloat(h % 1000) / 1000
    }
}

/// A red stroke running around the inside of the pill while Katana listens.
private struct RunningEdge: View {
    private static let lap = 2.4
    private static let length: CGFloat = 0.3

    var body: some View {
        TimelineView(.animation) { context in
            let start = CGFloat(
                (context.date.timeIntervalSinceReferenceDate / Self.lap).truncatingRemainder(dividingBy: 1)
            )
            let end = start + Self.length
            let lineWidth = max(1.5, 2 * pillScale)
            let shape = Capsule().inset(by: lineWidth / 2)
            let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            ZStack {
                shape.trim(from: start, to: min(end, 1))
                    .stroke(KatanaTheme.voiceEdge, style: style)
                if end > 1 {
                    shape.trim(from: 0, to: end - 1)
                        .stroke(KatanaTheme.voiceEdge, style: style)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Offset, blur and fade, for things that slide out from behind the pill or swap inside it.
private struct Tucked: ViewModifier {
    let x: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: x)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

fileprivate extension AnyTransition {
    /// Slides in from `x` points away (behind the pill), sharpening as it arrives.
    static func tucked(x: CGFloat) -> AnyTransition {
        .modifier(active: Tucked(x: x, blur: 4, opacity: 0), identity: Tucked(x: 0, blur: 0, opacity: 1))
    }

    /// Fades through a blur, for the mic icon and the bars swapping places.
    static var blurFade: AnyTransition {
        .modifier(active: Tucked(x: 0, blur: 6, opacity: 0), identity: Tucked(x: 0, blur: 0, opacity: 1))
    }
}
