import SwiftUI

struct ContentView: View {
    @State private var entryViewModel = EntryFlowViewModel(apiClient: TravelAPIClient())
    @Environment(BookingService.self) private var bookingService

    var body: some View {
        TabView {
            Tab("Discover", systemImage: "sparkles") {
                NavigationStack {
                    EntryFlowView()
                        .task { await entryViewModel.load() }
                }
                .environment(entryViewModel)
            }

            Tab("My Trips", systemImage: "suitcase.fill") {
                MyTripsView(bookingService: bookingService)
            }
        }
        .tint(.green)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let service = BookingService()
        ContentView()
            .environment(service)
    }
}
