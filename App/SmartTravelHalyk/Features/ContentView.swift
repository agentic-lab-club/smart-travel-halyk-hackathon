import SwiftUI

struct ContentView: View {
    @State private var viewModel = EntryFlowViewModel(apiClient: .mockingFallback())

    var body: some View {
        NavigationStack {
            EntryFlowView()
                .task { await viewModel.load() }
        }
        .environment(viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
