import SwiftUI

struct RouteNavigatorView: View {
    let viewModel: SelectedTripViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(viewModel.trip.routeNavigator.enumerated()), id: \.element.stopId) { index, stop in
                    HStack(spacing: 0) {
                        Button {
                            selectStop(stop)
                        } label: {
                            RouteStopPill(stop: stop)
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.trip.routeNavigator.count - 1,
                           let transport = stop.transportToNext {
                            TransportConnector(transport: transport)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func selectStop(_ stop: RouteStop) {
        if let coords = stop.coordinates {
            _ = viewModel.tapMarker(markerId: nearestMarkerId(to: coords) ?? "")
        } else if let seg = viewModel.trip.segments.first(where: { stop.startDate.hasPrefix($0.date) }) {
            viewModel.tapSegment(seg.segmentId)
        }
    }

    private func nearestMarkerId(to coords: Coordinates) -> String? {
        viewModel.trip.map.markers.min(by: {
            let d0 = abs($0.lat - coords.lat) + abs($0.lng - coords.lng)
            let d1 = abs($1.lat - coords.lat) + abs($1.lng - coords.lng)
            return d0 < d1
        })?.markerId
    }
}

private struct RouteStopPill: View {
    let stop: RouteStop

    var body: some View {
        Text(stop.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }
}

private struct TransportConnector: View {
    let transport: TransportType

    var body: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 8, height: 1.5)
            Image(systemName: iconForTransport)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 8, height: 1.5)
        }
        .padding(.horizontal, 2)
    }

    private var iconForTransport: String {
        switch transport {
        case .flight:           return "airplane"
        case .car, .rentalCar:  return "car.fill"
        case .bus:              return "bus.fill"
        case .train:            return "tram.fill"
        case .taxi:             return "car.fill"
        case .shuttle:          return "bus.fill"
        case .publicTransport:  return "bus.fill"
        case .walk:             return "figure.walk"
        }
    }
}
