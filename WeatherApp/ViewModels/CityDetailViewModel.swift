import Foundation

@MainActor
final class CityDetailViewModel {

    let city: City

    private(set) var weather: Weather?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var onChange: (() -> Void)?

    private let weatherService: any WeatherFetching
    private let favoritesStore: any FavoritesStoring

    var isFavorite: Bool { favoritesStore.contains(city) }

    init(
        city: City,
        weatherService: any WeatherFetching,
        favoritesStore: any FavoritesStoring
    ) {
        self.city = city
        self.weatherService = weatherService
        self.favoritesStore = favoritesStore
        // Render any cached value immediately so the user sees the place
        // they tapped before the network call returns.
        self.weather = weatherService.cachedForecast(for: city)
        favoritesStore.addObserver(self) { [weak self] _ in
            Task { @MainActor in self?.onChange?() }
        }
    }

    deinit { favoritesStore.removeObserver(self) }

    func load() async {
        // Only show a spinner if we have no cached value to display.
        isLoading = weather == nil
        errorMessage = nil
        onChange?()
        do {
            weather = try await weatherService.forecast(for: city)
        } catch {
            if weather == nil { errorMessage = "Couldn't load forecast" }
        }
        isLoading = false
        onChange?()
    }

    func toggleFavorite() {
        favoritesStore.toggle(city)
    }
}
