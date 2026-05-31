import SwiftUI
import UIKit

struct EntryFlowView: View {
    @Environment(EntryFlowViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel
        stateContent
            .navigationDestination(isPresented: $vm.isShowingGeneratedTrip) {
                if let trip = vm.generatedTrip {
                    SelectedTripView(trip: trip, apiClient: vm.apiClient)
                }
            }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .loaded:
            entryContent
        case .failed(let message):
            ContentUnavailableView(
                "Travel is unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparing smart trips")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryContent: some View {
        let planningBinding = Binding(
            get: { viewModel.isPlanning },
            set: { if !$0 && viewModel.planningState != .confirmed { viewModel.resetPlanning() } }
        )
        return ScrollView {
            RecommendationFeedPager(viewModel: self.viewModel)
        }
        .contentMargins(16, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                FeedSegmentBar(viewModel: self.viewModel)
                    .contentMargins(.horizontal, 16, for: .scrollContent)

                ChatbotInputCapsule(viewModel: self.viewModel)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 10)
        }
        .sheet(isPresented: planningBinding) {
            PlanningSheet(viewModel: self.viewModel)
        }
    }
}

struct EntryFlowView_Previews: PreviewProvider {
    static var previews: some View {
        EntryFlowViewPreview()
    }

    private struct EntryFlowViewPreview: View {
        @State private var viewModel = EntryFlowViewModel.previewLoaded

        var body: some View {
            EntryFlowView()
                .environment(viewModel)
        }
    }
}

struct PlanningSheet_Previews: PreviewProvider {
    static var previews: some View {
        EntryFlowViewPreview()
    }

    private struct EntryFlowViewPreview: View {
        var body: some View {
            PlanningSheet(viewModel: .previewLoaded)
        }
    }
}
