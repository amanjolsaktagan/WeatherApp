import Foundation

struct City: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let country: String?
    let admin1: String?
    let latitude: Double
    let longitude: Double

    var subtitle: String {
        [admin1, country].compactMap { $0 }.joined(separator: ", ")
    }
}
