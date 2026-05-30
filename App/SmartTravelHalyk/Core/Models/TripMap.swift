import Foundation

struct TripMap: Codable, Equatable {
    let initialCamera: MapCamera
    let markers: [MapMarker]
    let routes: [MapRoute]
}
