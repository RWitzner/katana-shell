import SwiftUI

/// "+ New task": what should it do, and which model. Return starts it, Escape cancels.
public struct NewTaskSheet: View {
    public static let models = ["Defaults", "Fable 5.5", "Opus 5.5", "Sonnet 5.5", "Haiku 5.5"]

    let onStart: (_ prompt: String, _ model: String) -> Void
    let onCancel: () -> Void
    @State private var prompt = ""
    @State private var model = NewTaskSheet.models[0]
    @FocusState private var focused: Bool

    public init(onStart: @escaping (_ prompt: String, _ model: String) -> Void, onCancel: @escaping () -> Void) {
        self.onStart = onStart
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New task")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KatanaTheme.textTitle)

            HStack(spacing: 6) {
                ForEach(Self.models, id: \.self) { item in
                    ModelChip(title: item, isSelected: model == item) { model = item }
                }
            }

            TextField(
                "",
                text: $prompt,
                prompt: Text("What should it do?").foregroundStyle(KatanaTheme.textSecondary),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(KatanaTheme.bodyFont)
            .foregroundStyle(KatanaTheme.textPrimary)
            .lineLimit(3...8)
            .focused($focused)
            .onSubmit(start)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: KatanaTheme.composerCornerRadius, style: .continuous)
                    .strokeBorder(focused ? KatanaTheme.raisedBorder : KatanaTheme.paneBorder, lineWidth: 1)
            )

            HStack(spacing: 14) {
                Spacer()
                GhostButton(title: "Cancel", shortcutHint: "esc", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                PrimaryButton(title: "Start", shortcutHint: "↩", action: start)
                    .opacity(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(KatanaTheme.paneBackground)
        .onAppear { focused = true }
    }

    private func start() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onStart(trimmed, model)
    }
}

private struct ModelChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        Button(action: action) {
            Text(title)
                .font(KatanaTheme.metaFont)
                .foregroundStyle(isSelected ? KatanaTheme.textTitle : KatanaTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(shape.fill(isSelected ? KatanaTheme.raised : (hovering ? KatanaTheme.hover : .clear)))
                .overlay(shape.strokeBorder(isSelected ? KatanaTheme.raisedBorder : KatanaTheme.paneBorder, lineWidth: 1))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
