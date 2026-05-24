import Foundation

struct Place: Sendable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
}

extension Place {
    /// Synthesises a `City` for use with the forecast/detail flow.
    /// Uses a negative id so it never collides with Open-Meteo geocoding ids.
    func asCity() -> City {
        City(
            id: -1,
            name: name,
            country: nil,
            admin1: nil,
            latitude: latitude,
            longitude: longitude
        )
    }
}
