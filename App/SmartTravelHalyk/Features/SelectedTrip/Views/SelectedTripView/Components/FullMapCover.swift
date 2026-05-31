import SwiftUI

struct FullMapCover: View {
    @Bindable var viewModel: SelectedTripViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            TripMapView(viewModel: viewModel, isFullScreen: true)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
        .overlay(alignment: .bottom) {
            ScrollView {
                SegmentedTimelineView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(maxHeight: 320)
            .background(.ultraThickMaterial, in: ConcentricRectangle(
                topLeadingCorner: .concentric(minimum: 16),
                topTrailingCorner: .concentric(minimum: 16)
            ))
            .clipShape(ConcentricRectangle(
                topLeadingCorner: .concentric(minimum: 16),
                topTrailingCorner: .concentric(minimum: 16)
            ))
            .scenePadding()
        }
        .ignoresSafeArea()
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
