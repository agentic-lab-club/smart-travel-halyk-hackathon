import SwiftUI

@main
struct SmartTravelHalykApp: App {
    @State private var bookingService = BookingService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bookingService)
                .task { bookingService.load() }
        }
    }
}
