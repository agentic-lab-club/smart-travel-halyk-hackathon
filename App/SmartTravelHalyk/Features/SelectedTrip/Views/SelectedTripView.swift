import SwiftUI

struct SelectedTripView: View {
    @State private var viewModel: SelectedTripViewModel

    private let heroHeight: CGFloat

    init(trip: TripDetailsResponse) {
        _viewModel = State(initialValue: SelectedTripViewModel(trip: trip))
        if let img = UIImage(named: "ExampleTripImage") {
            heroHeight = UIScreen.main.bounds.width * img.size.height / img.size.width
        } else {
            heroHeight = 300
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // ── Hero image (elastic stretch) ───────────────────────
                    GeometryReader { geo in
                        let minY = geo.frame(in: .named("scroll")).minY
                        let stretch = max(0, minY)

                        Image("ExampleTripImage")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: heroHeight + stretch)
                            .clipped()
                            .offset(y: -stretch)
                    }
                    .frame(height: heroHeight)

                    // ── Main content ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        
                        TripHeaderView(viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 14)

                        // TODO: Lets add sticky bar to the header of the scrollview. There we would have Tabs like Hotel (hotel details, rating, ability to upgrade), Plane(upgrade to the business and etc. Ability to select the seat), Destination (map with stops as we have).

                        // TODO: Should open fullsheetcover from package with itinerary at the bottom. it should open with zoom animation
                        TripMapView(viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)

                        // TODO: The click on the segment should open the map and focus on the segment location with zoom animation
                        TripSectionHeader(
                            "Itinerary",
                            "\(viewModel.trip.durationDays) days · \(viewModel.trip.segments.count) steps"
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                        SegmentedTimelineView(viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 28)

                        if let hotel = viewModel.hotelDetails {
                            TripSectionHeader("Hotel", hotel.name)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)

                            HotelDecisionView(
                                hotel: hotel,
                                fullHotel: viewModel.hotelFullDetails
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 28)
                        }
                    }
                    .padding(.bottom, 40)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
            .onChange(of: viewModel.selectedSegmentId) { _, newId in
                guard let id = newId else { return }
                withAnimation(.smooth) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section header

private struct TripSectionHeader: View {
    let title: String
    let subtitle: String

    init(_ title: String, _ subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title2.bold())
            Spacer()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

struct SelectedTripView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SelectedTripView(trip: MockTravelData.tripDetails)
        }
    }
}
