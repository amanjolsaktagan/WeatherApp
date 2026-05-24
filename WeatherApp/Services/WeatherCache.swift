import Foundation

protocol WeatherCaching: AnyObject {
    /// Returns any cached value for the coordinate, regardless of age.
    func load(latitude: Double, longitude: Double) -> Weather?
    /// Returns the cached value only if it was fetched within `ttl` seconds.
    func loadIfFresh(latitude: Double, longitude: Double, ttl: TimeInterval) -> Weather?
    func store(_ weather: Weather, latitude: Double, longitude: Double)
}

final class WeatherCache: WeatherCaching {

    static let shared = WeatherCache()

    private struct Entry: Codable {
        let weather: Weather
        let fetchedAt: Date
    }

    private let directory: URL
    private let queue = DispatchQueue(label: "WeatherCache", qos: .utility, attributes: .concurrent)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL? = nil) {
        let caches = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
        let dir = directory ?? caches.appendingPathComponent("WeatherCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.directory = dir
    }

    func load(latitude: Double, longitude: Double) -> Weather? {
        readEntry(latitude: latitude, longitude: longitude)?.weather
    }

    func loadIfFresh(latitude: Double, longitude: Double, ttl: TimeInterval) -> Weather? {
        guard let entry = readEntry(latitude: latitude, longitude: longitude),
              Date().timeIntervalSince(entry.fetchedAt) < ttl else { return nil }
        return entry.weather
    }

    func store(_ weather: Weather, latitude: Double, longitude: Double) {
        let url = fileURL(latitude: latitude, longitude: longitude)
        let entry = Entry(weather: weather, fetchedAt: Date())
        queue.async(flags: .barrier) { [encoder] in
            guard let data = try? encoder.encode(entry) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func readEntry(latitude: Double, longitude: Double) -> Entry? {
        let url = fileURL(latitude: latitude, longitude: longitude)
        return queue.sync { [decoder] in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(Entry.self, from: data)
        }
    }

    private func fileURL(latitude: Double, longitude: Double) -> URL {
        // 3-decimal rounding ≈ 110m granularity; safe for distinct cities.
        let name = String(format: "weather_%.3f_%.3f.json", latitude, longitude)
        return directory.appendingPathComponent(name)
    }
}
