import SwiftUI

/// The scroll view's own coordinate space, to read how far its content has moved.
private let subtleScrollSpace = "katana-subtle-scroll"

/// A vertical scroll view with a thin, quiet indicator instead of the system
/// scroller: a narrow translucent line with no track. It shows while you scroll
/// and when the pointer enters, then fades out. It is not draggable; scroll with
/// the trackpad or wheel.
///
/// Use it like `ScrollView`: scroll modifiers such as `.defaultScrollAnchor` and
/// `ScrollViewReader` work as usual.
public struct SubtleScrollView<Content: View>: View {
    private let content: Content

    @State private var contentFrame: CGRect = .zero
    @State private var viewportHeight: CGFloat = 0
    @State private var isShowing = false
    @State private var hideTask: Task<Void, Never>?

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack { content }
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named(subtleScrollSpace))
                } action: { frame in
                    // Only real scrolling shows the indicator, not the first layout.
                    let scrolled = contentFrame.height > 0 && abs(frame.minY - contentFrame.minY) > 0.5
                    contentFrame = frame
                    if scrolled { show() }
                }
        }
        .coordinateSpace(.named(subtleScrollSpace))
        .scrollIndicators(.never)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            viewportHeight = height
        }
        .overlay(alignment: .topTrailing) { thumb }
        .onHover { inside in
            if inside { show() }
        }
        .onDisappear { hideTask?.cancel() }
    }

    @ViewBuilder
    private var thumb: some View {
        let inset = KatanaTheme.scrollThumbInset
        let track = viewportHeight - inset * 2
        if viewportHeight > 0, contentFrame.height > viewportHeight + 1, track > 0 {
            let length = min(
                KatanaTheme.scrollThumbMaxLength,
                max(KatanaTheme.scrollThumbMinLength, track * viewportHeight / contentFrame.height)
            )
            let travel = contentFrame.height - viewportHeight
            let progress = min(1, max(0, -contentFrame.minY / travel))
            Capsule()
                .fill(KatanaTheme.scrollThumb)
                .frame(width: KatanaTheme.scrollThumbWidth, height: length)
                .offset(x: -KatanaTheme.scrollThumbTrailing, y: inset + (track - length) * progress)
                .opacity(isShowing ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isShowing)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// Show the indicator, and hide it again once scrolling has been still for a moment.
    private func show() {
        isShowing = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(KatanaTheme.scrollThumbLinger))
            guard !Task.isCancelled else { return }
            isShowing = false
        }
    }
}
