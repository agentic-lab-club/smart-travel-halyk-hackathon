import SwiftUI
import UIKit

enum DetailTab: String, CaseIterable {
    case plane, hotel, destination

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .destination: return "map.fill"
        case .hotel: return "bed.double.fill"
        case .plane: return "airplane"
        }
    }
}

struct FlightPlan: Identifiable {
    enum Direction {
        case arrival
        case departure

        var title: String {
            switch self {
            case .arrival: return "Outbound"
            case .departure: return "Return"
            }
        }

        var icon: String {
            switch self {
            case .arrival: return "airplane.arrival"
            case .departure: return "airplane.departure"
            }
        }
    }

    let id: String
    let segment: ItinerarySegment
    let flight: FlightInfo
    let direction: Direction
    let checkoutTime: String?
    let recommendedLeaveHotelTime: String?
}

extension ItinerarySegment {
    var flightPlan: FlightPlan? {
        switch details {
        case .arrival(let details):
            return FlightPlan(
                id: segmentId,
                segment: self,
                flight: details.flight,
                direction: .arrival,
                checkoutTime: nil,
                recommendedLeaveHotelTime: nil
            )
        case .departure(let details):
            return FlightPlan(
                id: segmentId,
                segment: self,
                flight: details.flight,
                direction: .departure,
                checkoutTime: details.checkoutTime,
                recommendedLeaveHotelTime: details.recommendedLeaveHotelTime
            )
        default:
            return nil
        }
    }
}

struct SelectedTripView: View {
    @State private var viewModel: SelectedTripViewModel
    @State private var selectedTab: DetailTab = .destination
    @State private var showFullMap = false
    @State private var selectedFlightForDetail: FlightPlan?
    @State private var showPurchase = false

    private let heroAspectRatio: CGFloat

    private let apiClient: TravelAPIClient

    init(trip: TripDetailsResponse, apiClient: TravelAPIClient = TravelAPIClient()) {
        _viewModel = State(initialValue: SelectedTripViewModel(trip: trip))
        self.apiClient = apiClient
        if let img = UIImage(named: "ExampleTripImage") {
            heroAspectRatio = img.size.height / img.size.width
        } else {
            heroAspectRatio = 3 / 4
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let heroHeight = proxy.size.width * heroAspectRatio

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
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

                            TripHeaderView(viewModel: viewModel)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 14)
                                .background(Color(.systemGroupedBackground))
                                .offset(y: 50)
                                .zIndex(2)
                        }

                        Section {
                            tabContent
                                .padding(.top, 20)
                                .padding(.bottom, 40)
                                .background(Color(.systemGroupedBackground))
                        } header: {
                            DetailTabBar(selected: $selectedTab)
                                .zIndex(1)
                                .padding(.top, topInset + 120)
                                .background(Color(.systemGroupedBackground))
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .coordinateSpace(name: "scroll")
                .ignoresSafeArea(edges: .top)
                .safeAreaInset(edge: .bottom) {
                    BookTripFooter(totalCost: viewModel.effectiveTotalCost) {
                        showPurchase = true
                    }
                }
                .onChange(of: viewModel.selectedSegmentId) { _, newId in
                    guard let id = newId else { return }
                    withAnimation(.smooth) {
                        scrollProxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFullMap) {
            FullMapCover(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showPurchase) {
            TripPurchaseView(trip: viewModel.trip)
        }
        .fullScreenCover(item: $selectedFlightForDetail) { plan in
            FlightDetailView(
                flight: plan.flight,
                segmentTitle: plan.segment.title,
                directionTitle: plan.direction.title,
                directionIcon: plan.direction.icon,
                adultCount: viewModel.adultCount,
                childCount: viewModel.childCount,
                onClose: { selectedFlightForDetail = nil }
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .destination: destinationTab
        case .hotel: hotelTab
        case .plane: planeTab
        }
    }

    @ViewBuilder
    private var destinationTab: some View {
        VStack {
            Button {
                showFullMap = true
            } label: {
                TripMapView(viewModel: viewModel)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            TripSectionHeader(
                "Itinerary",
                "\(viewModel.trip.durationDays) days · \(viewModel.segments.count) steps"
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            SegmentedTimelineView(viewModel: viewModel, onSegmentTap: {
                showFullMap = true
            })
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var hotelTab: some View {
        if let hotel = viewModel.hotelDetails {
            TripSectionHeader("Hotel", hotel.name)
                .padding(.horizontal, 16)

            let bindableVM = Bindable(viewModel)
            HotelDecisionView(
                hotel: hotel,
                fullHotel: viewModel.hotelFullDetails,
                selectedRoomId: bindableVM.selectedHotelRoomId
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .task { await viewModel.loadHotelDetails(apiClient: apiClient) }
        } else {
            ContentUnavailableView("No Hotel Booked", systemImage: "bed.double")
                .padding(.top, 40)
        }
    }

    @ViewBuilder
    private var planeTab: some View {
        let flights = viewModel.trip.segments.compactMap(\.flightPlan)

        if flights.isEmpty {
            ContentUnavailableView("No Flights", systemImage: "airplane")
                .padding(.top, 40)
        } else {
            TripSectionHeader("Flights", flights.count == 1 ? "1 flight" : "\(flights.count) flights")
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                FlightRouteSummaryCard(flights: flights)

                ForEach(flights) { flight in
                    FlightDetailCard(plan: flight) {
                        selectedFlightForDetail = flight
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }
}

struct SelectedTripView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SelectedTripView(trip: MockTravelData.tripDetails)
        }
    }
}

struct FullMapCover_Previews: PreviewProvider {
    static var previews: some View {
        FullMapCover(viewModel: .preview)
    }
}
