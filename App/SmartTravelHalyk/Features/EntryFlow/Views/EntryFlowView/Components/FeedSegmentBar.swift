import SwiftUI

struct FeedSegmentBar: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach(self.viewModel.feedSegments) { segment in
                        Button {
                            withAnimation(.snappy) {
                                self.viewModel.selectedFeedSegment = segment
                            }
                        } label: {
                            FeedSegmentChip(
                                segment: segment,
                                count: self.viewModel.recommendations(for: segment).count,
                                isSelected: self.viewModel.selectedFeedSegment == segment
                            )
                        }
                        .buttonStyle(.plain)
                        .scrollTargetLayout()
                    }
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }
}
