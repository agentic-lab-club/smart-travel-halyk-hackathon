import SwiftUI

struct ChatbotInputCapsule: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.green)

            TextField("Tell us about your trip", text: self.$viewModel.chatbotPrompt)
                .submitLabel(.send)
                .onSubmit { Task { await self.viewModel.submitChatbotPrompt() } }

            if !self.viewModel.chatbotPrompt.isEmpty {
                Button { Task { await self.viewModel.submitChatbotPrompt() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .disabled(self.viewModel.chatbotPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .transition(.move(edge: .trailing).combined(with: .blurReplace))
            }
        }
        .animation(.default, value: viewModel.chatbotPrompt)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .liquidGlassCapsule()
    }
}

extension View {
    @ViewBuilder
    func liquidGlassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            background(.ultraThinMaterial, in: .capsule)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
        }
    }
}
