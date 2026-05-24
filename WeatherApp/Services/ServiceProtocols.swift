import Foundation

/// Class-only so existential storage is a single retained reference rather than a value-box.
protocol WeatherFetching: AnyObject {
    func searchCities(matching query: String) async throws -> [City]
    func forecast(for city: City) async throws -> Weather
    func forecast(latitude: Double, longitude: Double) async throws -> Weather
    /// Returns any cached forecast for the location synchronously, regardless of age.
    /// Useful for rendering immediately on launch before triggering a refresh.
    func cachedForecast(for city: City) -> Weather?
    func cachedForecast(latitude: Double, longitude: Double) -> Weather?
}

protocol FavoritesStoring: AnyObject {
    var cities: [City] { get }
    func contains(_ city: City) -> Bool
    func add(_ city: City)
    func remove(_ city: City)
    func toggle(_ city: City)
    /// Adds a weak-ref observer. The observer is dropped automatically when `owner` deinits.
    func addObserver(_ owner: AnyObject, block: @escaping ([City]) -> Void)
    func removeObserver(_ owner: AnyObject)
}

protocol LocationProviding: AnyObject {
    func requestCurrentPlace() async throws -> Place
}
