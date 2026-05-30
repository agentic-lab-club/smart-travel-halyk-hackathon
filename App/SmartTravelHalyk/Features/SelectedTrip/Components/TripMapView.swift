import SwiftUI
import MapKit

struct TripMapView: View {
    @Bindable var viewModel: SelectedTripViewModel
    var isFullScreen: Bool = false

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.trip.map.routes, id: \.routeId) { route in
                if let from = viewModel.trip.map.markers.first(where: { $0.markerId == route.fromMarkerId }),
                   let to   = viewModel.trip.map.markers.first(where: { $0.markerId == route.toMarkerId }) {
                    MapPolyline(coordinates: [
                        CLLocationCoordinate2D(latitude: from.lat, longitude: from.lng),
                        CLLocationCoordinate2D(latitude: to.lat,   longitude: to.lng)
                    ])
                    .stroke(Color.green.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, dash: [6, 3]))
                }
            }

            ForEach(viewModel.trip.map.markers, id: \.markerId) { marker in
                Annotation(
                    marker.title,
                    coordinate: CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lng),
                    anchor: .bottom
                ) {
                    MapMarkerPin(
                        marker: marker,
                        isSelected: viewModel.selectedSegmentId.map { $0 == marker.segmentId } ?? false
                    )
                    .onTapGesture {
                        _ = viewModel.tapMarker(markerId: marker.markerId)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls { }
        .frame(height: isFullScreen ? nil : 248)
        .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 16))
    }
}

struct MapMarkerPin: View {
    let marker: MapMarker
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(markerColor.opacity(isSelected ? 1 : 0.85))
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: markerColor.opacity(0.4), radius: isSelected ? 8 : 4)

                Image(systemName: marker.icon ?? iconForType)
                    .font(.system(size: isSelected ? 17 : 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Triangle()
                .fill(markerColor.opacity(isSelected ? 1 : 0.85))
                .frame(width: 8, height: 5)
        }
        .animation(.smooth(duration: 0.2), value: isSelected)
    }

    private var markerColor: Color {
        switch marker.type {
        case .airport:     return .blue
        case .hotel:       return .orange
        case .attraction:  return .green
        case .event:       return .purple
        case .restaurant:  return .red
        case .station:     return .teal
        default:           return .gray
        }
    }

    private var iconForType: String {
        switch marker.type {
        case .airport:    return "airplane"
        case .hotel:      return "bed.double.fill"
        case .attraction: return "binoculars.fill"
        case .event:      return "star.fill"
        case .restaurant: return "fork.knife"
        case .station:    return "tram.fill"
        default:          return "mappin"
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
