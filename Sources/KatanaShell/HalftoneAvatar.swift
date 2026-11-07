import AppKit
import SwiftUI

/// Katana's face. Pass Katana's real portrait as `image`; without one it draws
/// a halftone head-and-shoulders stand-in in the same dotted style.
/// Supply a local GIF URL to animate while `isSpeaking` is true.
public struct KatanaAvatar: View {
    let image: Image?
    let speakingAnimationURL: URL?
    let isSpeaking: Bool
    let size: CGFloat

    public init(image: Image? = nil, speakingAnimationURL: URL? = nil, isSpeaking: Bool = false, size: CGFloat) {
        self.image = image
        self.speakingAnimationURL = speakingAnimationURL
        self.isSpeaking = isSpeaking
        self.size = size
    }

    public var body: some View {
        Group {
            if isSpeaking, let speakingAnimationURL {
                AnimatedAvatar(url: speakingAnimationURL)
                    .id(speakingAnimationURL)
            } else if let image {
                image.resizable().interpolation(.none).scaledToFit()
            } else {
                HalftoneStandIn(dotStep: max(2, size / 34))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Katana")
        .accessibilityValue(isSpeaking ? "Speaking" : "Idle")
    }
}

/// AppKit respects the GIF's frame timing and loop count. This view exists only
/// during speech, so the next reply starts a fresh animation.
private struct AnimatedAvatar: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageFrameStyle = .none
        view.image = NSImage(contentsOf: url)
        view.animates = true
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    static func dismantleNSView(_ nsView: NSImageView, coordinator: ()) {
        nsView.animates = false
        nsView.image = nil
    }
}

/// Square white dots whose size follows a soft head-and-shoulders shape plus noise.
private struct HalftoneStandIn: View {
    let dotStep: CGFloat

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / dotStep)
            let rows = Int(size.height / dotStep)
            for row in 0..<rows {
                for column in 0..<columns {
                    let x = (CGFloat(column) + 0.5) / CGFloat(columns)
                    let y = (CGFloat(row) + 0.5) / CGFloat(rows)
                    let level = Self.level(x: x, y: y, noise: Self.noise(column, row))
                    guard level > 0.18 else { continue }
                    let side = dotStep * min(1, level) * 0.92
                    let rect = CGRect(
                        x: CGFloat(column) * dotStep + (dotStep - side) / 2,
                        y: CGFloat(row) * dotStep + (dotStep - side) / 2,
                        width: side,
                        height: side
                    )
                    context.fill(Path(rect), with: .color(.white.opacity(0.35 + 0.65 * min(1, level))))
                }
            }
        }
    }

    /// Brightness 0...1 at a point: head, a darker eye band, shoulders, ragged edges.
    private static func level(x: CGFloat, y: CGFloat, noise: CGFloat) -> CGFloat {
        let head = 1 - hypot((x - 0.5) / 0.27, (y - 0.42) / 0.34)
        let shoulders = 1 - hypot((x - 0.5) / 0.5, (y - 1.08) / 0.34)
        var value = max(head, shoulders) * 1.6
        if abs(y - 0.40) < 0.05, abs(x - 0.5) > 0.06, abs(x - 0.5) < 0.2 { value *= 0.35 }
        if abs(y - 0.6) < 0.025, abs(x - 0.5) < 0.09 { value *= 0.5 }
        return value + (noise - 0.5) * 0.9
    }

    private static func noise(_ a: Int, _ b: Int) -> CGFloat {
        var h = UInt32(truncatingIfNeeded: a &* 73_856_093 ^ b &* 19_349_663)
        h ^= h >> 13
        h = h &* 1_274_126_177
        h ^= h >> 16
        return CGFloat(h % 1000) / 1000
    }
}
