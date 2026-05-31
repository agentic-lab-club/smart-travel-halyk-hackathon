import SwiftUI

struct SegmentedTimelineView: View {
    let viewModel: SelectedTripViewModel
    var onSegmentTap: (() -> Void)? = nil

    @State private var chatbotMode: ChatbotMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SwipeViewGroup {
                ForEach(Array(viewModel.segments.enumerated()), id: \.element.segmentId) { index, segment in
                    TimelineRow(
                        segment: segment,
                        isSelected: viewModel.selectedSegmentId == segment.segmentId,
                        isLast: index == viewModel.segments.count - 1,
                        onTap: {
                            viewModel.tapSegment(segment.segmentId)
                            onSegmentTap?()
                        },
                        onDelete: segment.type.isReplaceable
                            ? { viewModel.deleteSegment(segment.segmentId) }
                            : nil,
                        onReplace: segment.type.isReplaceable
                            ? { chatbotMode = .replaceSegment(segment) }
                            : nil
                    )
                    .id(segment.segmentId)
                }
            }

            Divider()

            AskAIButton { chatbotMode = .addPlaces }
                .padding(.top, 12)
        }
        .sheet(item: $chatbotMode) { mode in
            ItineraryChatbotSheet(viewModel: viewModel, mode: mode)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct SegmentedTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SegmentedTimelineView(viewModel: .preview)
                .background(.secondary.quaternary)
        }
        .scenePadding()
        .background(.secondary.quaternary)
    }
}
