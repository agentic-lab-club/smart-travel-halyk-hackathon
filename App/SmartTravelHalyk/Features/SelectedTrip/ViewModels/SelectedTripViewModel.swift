import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SelectedTripViewModel {
    let trip: TripDetailsResponse
    var selectedMode: TripMode
    var selectedSegmentId: String?
    var cameraPosition: MapCameraPosition

    var currentModeVariant: ModeVariant? { trip.modeVariants[selectedMode] }

    var effectiveTotalCost: Money {
        if let v = currentModeVariant {
            return Money(amount: Double(v.totalCost), currency: trip.currency)
        }
        return trip.summary.estimatedTotalCost
    }

    var effectiveCashback: Money? { trip.summary.estimatedTotalCashback }

    var currentTradeoffLabel: String? { currentModeVariant?.tradeoffLabel }

    var effectiveBudget: BudgetBreakdown { MockTravelData.budget(for: selectedMode) }

    /// City name from the first day-itinerary segment; falls back to trip title.
    var destinationCity: String {
        for seg in trip.segments {
            if case .dayItinerary(let d) = seg.details { return d.city }
        }
        return trip.title
    }

    var hotelSegment: ItinerarySegment? {
        trip.segments.first { seg in
            if case .hotel = seg.details { return true }
            return false
        }
    }

    var hotelDetails: HotelDetails? {
        guard let seg = hotelSegment, case .hotel(let h) = seg.details else { return nil }
        return h
    }

    var hotelFullDetails: HotelDetailsFull? {
        guard hotelDetails?.hotelId == MockTravelData.hotelDetailsFull.hotelId else { return nil }
        return MockTravelData.hotelDetailsFull
    }

    init(trip: TripDetailsResponse) {
        self.trip = trip
        self.selectedMode = trip.selectedMode
        let cam = trip.map.initialCamera
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: cam.centerLat, longitude: cam.centerLng),
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
        ))
    }

    static var preview: SelectedTripViewModel {
        SelectedTripViewModel(trip: MockTravelData.tripDetails)
    }

    func tapSegment(_ segmentId: String) {
        let deselecting = selectedSegmentId == segmentId
        withAnimation(.smooth(duration: 0.25)) {
            selectedSegmentId = deselecting ? nil : segmentId
        }
        guard !deselecting,
              let segment = trip.segments.first(where: { $0.segmentId == segmentId }),
              let markerId = segment.linkedMarkerIds.first,
              let marker = trip.map.markers.first(where: { $0.markerId == markerId }) else { return }
        focusMap(lat: marker.lat, lng: marker.lng)
    }

    func tapMarker(markerId: String) -> String? {
        guard let marker = trip.map.markers.first(where: { $0.markerId == markerId }),
              let segId = marker.segmentId else { return nil }
        withAnimation(.smooth(duration: 0.25)) { selectedSegmentId = segId }
        focusMap(lat: marker.lat, lng: marker.lng)
        return segId
    }

    private func focusMap(lat: Double, lng: Double) {
        withAnimation(.smooth(duration: 0.45)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
            ))
        }
    }
}
