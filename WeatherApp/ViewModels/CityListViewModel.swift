import Foundation

@MainActor
final class CityListViewModel {

    enum Mode { case favorites, search }

    struct WeatherSnapshot {
        var temperatureCelsius: Double?
        var weatherCode: Int?
        var dailyHigh: Double?
        var dailyLow: Double?
        var isNight: Bool

        init(weather: Weather? = nil) {
            self.temperatureCelsius = weather?.current.temperature2m
            self.weatherCode = weather?.current.weatherCode
            self.dailyHigh = weather?.daily.temperature2mMax.first
            self.dailyLow = weather?.daily.temperature2mMin.first
            self.isNight = weather?.isNight ?? false
        }
    }

    struct FavoriteRow {
        let city: City
        var snapshot: WeatherSnapshot
    }

    struct CurrentLocationRow {
        let place: Place
        var snapshot: WeatherSnapshot
    }

    private(set) var mode: Mode = .favorites
    private(set) var favorites: [FavoriteRow] = []
    private(set) var currentLocation: CurrentLocationRow?
    private(set) var searchResults: [City] = []
    private(set) var isSearching = false

    var onChange: (() -> Void)?

    private let weatherService: any WeatherFetching
    private let favoritesStore: any FavoritesStoring
    private let locationService: any LocationProviding
    private var searchTask: Task<Void, Never>?

    init(
        weatherService: any WeatherFetching,
        favoritesStore: any FavoritesStoring,
        locationService: any LocationProviding
    ) {
        self.weatherService = weatherService
        self.favoritesStore = favoritesStore
        self.locationService = locationService
        syncFavorites(with: favoritesStore.cities)
        favoritesStore.addObserver(self) { [weak self] cities in
            Task { @MainActor in self?.syncFavorites(with: cities) }
        }
    }

    deinit { favoritesStore.removeObserver(self) }

    // MARK: Public API

    func refreshAll() async {
        async let location: Void = refreshCurrentLocation()
        async let favorites: Void = refreshFavoritesWeather()
        _ = await (location, favorites)
    }

    func refreshCurrentLocation() async {
        do {
            let place = try await locationService.requestCurrentPlace()
            let weather = try await weatherService.forecast(
                latitude: place.latitude,
                longitude: place.longitude
            )
            currentLocation = CurrentLocationRow(
                place: place,
                snapshot: WeatherSnapshot(weather: weather)
            )
        } catch {
            currentLocation = nil
        }
        onChange?()
    }

    func refreshFavoritesWeather() async {
        let cities = favorites.map(\.city)
        await withTaskGroup(of: (Int, Weather?).self) { [weatherService] group in
            for city in cities {
                let cityID = city.id
                group.addTask {
                    let weather = try? await weatherService.forecast(for: city)
                    return (cityID, weather)
                }
            }
            for await (cityID, weather) in group {
                guard let weather,
                      let index = favorites.firstIndex(where: { $0.city.id == cityID })
                else { continue }
                favorites[index].snapshot = WeatherSnapshot(weather: weather)
            }
        }
        onChange?()
    }

    func updateSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()

        guard !trimmed.isEmpty else {
            mode = .favorites
            searchResults = []
            isSearching = false
            onChange?()
            return
        }

        mode = .search
        isSearching = true
        onChange?()

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            let results = (try? await self.weatherService.searchCities(matching: trimmed)) ?? []
            guard !Task.isCancelled else { return }
            self.searchResults = results
            self.isSearching = false
            self.onChange?()
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        mode = .favorites
        searchResults = []
        isSearching = false
        onChange?()
    }

    // MARK: Helpers

    private func syncFavorites(with cities: [City]) {
        favorites = cities.map { city in
            if let existing = favorites.first(where: { $0.city.id == city.id }) {
                return existing
            }
            // Seed the snapshot from any cached forecast so the row renders
            // immediately on launch without waiting for the network round-trip.
            let cached = weatherService.cachedForecast(for: city)
            return FavoriteRow(city: city, snapshot: WeatherSnapshot(weather: cached))
        }
        onChange?()
    }
}
