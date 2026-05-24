import Foundation

enum WeatherServiceError: Error {
    case invalidURL
    case badResponse(Int)
}

final class WeatherService: WeatherFetching {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let cache: any WeatherCaching
    private let ttl: TimeInterval

    init(
        session: URLSession = .shared,
        cache: any WeatherCaching = WeatherCache.shared,
        ttl: TimeInterval = 15 * 60
    ) {
        self.session = session
        self.decoder = JSONDecoder()
        self.cache = cache
        self.ttl = ttl
    }

    // MARK: Geocoding

    func searchCities(matching query: String) async throws -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return (try decoder.decode(GeocodingResponse.self, from: data).results) ?? []
    }

    // MARK: Forecast (cache-aware)

    func forecast(for city: City) async throws -> Weather {
        try await forecast(latitude: city.latitude, longitude: city.longitude)
    }

    func forecast(latitude: Double, longitude: Double) async throws -> Weather {
        if let fresh = cache.loadIfFresh(latitude: latitude, longitude: longitude, ttl: ttl) {
            return fresh
        }
        do {
            let weather = try await fetchForecast(latitude: latitude, longitude: longitude)
            cache.store(weather, latitude: latitude, longitude: longitude)
            return weather
        } catch {
            // Network failure: fall back to stale cache if we have anything at all.
            if let stale = cache.load(latitude: latitude, longitude: longitude) {
                return stale
            }
            throw error
        }
    }

    func cachedForecast(for city: City) -> Weather? {
        cache.load(latitude: city.latitude, longitude: city.longitude)
    }

    func cachedForecast(latitude: Double, longitude: Double) -> Weather? {
        cache.load(latitude: latitude, longitude: longitude)
    }

    // MARK: Private

    private func fetchForecast(latitude: Double, longitude: Double) async throws -> Weather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return try decoder.decode(Weather.self, from: data)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw WeatherServiceError.badResponse(http.statusCode)
        }
    }
}
