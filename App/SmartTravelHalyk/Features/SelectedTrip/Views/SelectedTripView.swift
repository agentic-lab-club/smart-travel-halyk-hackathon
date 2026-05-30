import SwiftUI

private enum DetailTab: String, CaseIterable {
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

struct SelectedTripView: View {
    @State private var viewModel: SelectedTripViewModel
    @State private var selectedTab: DetailTab = .destination
    @State private var showFullMap = false
    @State private var selectedFlightForDetail: FlightPlan?
    @State private var showPurchase = false

    private let heroAspectRatio: CGFloat

    init(trip: TripDetailsResponse) {
        _viewModel = State(initialValue: SelectedTripViewModel(trip: trip))
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
                .padding(.bottom, 10)

            let bindableVM = Bindable(viewModel)
            HotelDecisionView(
                hotel: hotel,
                fullHotel: viewModel.hotelFullDetails,
                selectedRoomId: bindableVM.selectedHotelRoomId
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
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
                .padding(.bottom, 10)

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

// MARK: - Flight plan model

private struct FlightPlan: Identifiable {
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

private extension ItinerarySegment {
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

// MARK: - Flight summary card

private struct FlightRouteSummaryCard: View {
    let flights: [FlightPlan]

    private var totalPrice: Money? {
        let pricedFlights = flights.compactMap(\.flight.price)
        guard let currency = pricedFlights.first?.currency, pricedFlights.allSatisfy({ $0.currency == currency }) else {
            return nil
        }
        return Money(amount: pricedFlights.reduce(0) { $0 + $1.amount }, currency: currency)
    }

    private var totalDuration: String {
        FlightDisplay.duration(flights.reduce(0) { $0 + $1.flight.durationMinutes })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flight plan")
                        .font(.headline)
                    Text(flights.count == 1 ? "One confirmed leg" : "Round trip with \(flights.count) legs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(flights) { plan in
                        FlightAirportBadge(code: plan.flight.fromAirport, label: FlightDisplay.shortDate(plan.flight.departureTime))

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        FlightAirportBadge(code: plan.flight.toAirport, label: FlightDisplay.shortDate(plan.flight.arrivalTime))
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                FlightMetricPill(title: "Duration", value: totalDuration, icon: "clock.fill")
                FlightMetricPill(title: "Stops", value: flights.allSatisfy { $0.flight.stops == 0 } ? "Direct" : "With stops", icon: "checkmark.circle.fill")
                if let totalPrice {
                    FlightMetricPill(title: "Total", value: totalPrice.displayString, icon: "creditcard.fill")
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct FlightAirportBadge: View {
    let code: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 48, alignment: .leading)
    }
}

private struct FlightMetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Flight detail card

private struct FlightDetailCard: View {
    let plan: FlightPlan
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: plan.direction.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.green, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.direction.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(plan.segment.title)
                        .font(.headline)
                    Text("Day \(plan.segment.dayNumber) · \(FlightDisplay.shortDate(plan.flight.departureTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let price = plan.flight.price {
                    Text(price.displayString)
                        .font(.subheadline.weight(.bold))
                        .multilineTextAlignment(.trailing)
                }
            }

            FlightTimingRoute(plan: plan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                FlightInfoTile(title: "Airline", value: plan.flight.airline ?? "TBA", icon: "tag.fill")
                FlightInfoTile(title: "Flight", value: plan.flight.flightNumber ?? "TBA", icon: "number")
                FlightInfoTile(title: "Cabin", value: plan.flight.cabinClass.title, icon: "person.crop.square.fill")
                FlightInfoTile(title: "Stops", value: plan.flight.stops == 0 ? "Direct" : "\(plan.flight.stops) stop(s)", icon: "arrow.triangle.branch")
            }

            if let description = plan.segment.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }

            FlightChecklist(plan: plan)

            // Select seats button
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Select Seats")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct FlightTimingRoute: View {
    let plan: FlightPlan

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                FlightTimeBlock(
                    airport: plan.flight.fromAirport,
                    time: FlightDisplay.time(plan.flight.departureTime),
                    date: FlightDisplay.shortDate(plan.flight.departureTime),
                    alignment: .leading
                )

                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        Image(systemName: "airplane")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    Text(FlightDisplay.duration(plan.flight.durationMinutes))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                FlightTimeBlock(
                    airport: plan.flight.toAirport,
                    time: FlightDisplay.time(plan.flight.arrivalTime),
                    date: FlightDisplay.shortDate(plan.flight.arrivalTime),
                    alignment: .trailing
                )
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct FlightTimeBlock: View {
    let airport: String
    let time: String
    let date: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(time)
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(airport)
                .font(.caption.weight(.semibold))
            Text(date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 74, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct FlightInfoTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct FlightChecklist: View {
    let plan: FlightPlan

    var body: some View {
        let items = checklistItems

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before flight")
                    .font(.subheadline.weight(.semibold))

                ForEach(items, id: \.title) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var checklistItems: [(icon: String, title: String, subtitle: String)] {
        var items: [(String, String, String)] = []

        if let checkoutTime = plan.checkoutTime {
            items.append(("door.right.hand.open", "Check out by \(checkoutTime)", "Keep luggage ready before the return route."))
        }

        if let leaveTime = plan.recommendedLeaveHotelTime {
            items.append(("figure.walk", "Leave hotel by \(leaveTime)", "Recommended buffer for airport transfer and security."))
        }

        return items
    }
}

// MARK: - Detail tab bar

private struct DetailTabBar: View {
    @Binding var selected: DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.smooth(duration: 0.25)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selected == tab ? .green : .secondary)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selected == tab ? Color.green : Color.clear)
                            .frame(height: 2)
                    }
                    .animation(.smooth(duration: 0.25), value: selected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Full map cover

private struct FullMapCover: View {
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

// MARK: - Book trip footer

private struct BookTripFooter: View {
    let totalCost: Money
    let onBook: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total estimate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalCost.displayString)
                        .font(.headline.bold())
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: totalCost.amount)
                }

                Spacer()

                Button(action: onBook) {
                    Label("Book Trip", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: .green.opacity(pulse ? 0.55 : 0.25), radius: pulse ? 16 : 8, y: 4)
                        )
                        .scaleEffect(pulse ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }
                .buttonStyle(.plain)
                .onAppear { pulse = true }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Previews

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
