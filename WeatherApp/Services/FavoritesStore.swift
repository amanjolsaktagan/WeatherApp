import Foundation

final class FavoritesStore: FavoritesStoring {

    static let shared = FavoritesStore()

    private let defaults: UserDefaults
    private let key = "favoriteCities"

    private struct Observer {
        weak var owner: AnyObject?
        let block: ([City]) -> Void
    }
    private var observers: [Observer] = []

    private(set) var cities: [City] {
        didSet { persist(); notify() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([City].self, from: data) {
            self.cities = decoded
        } else {
            self.cities = []
        }
    }

    func contains(_ city: City) -> Bool {
        cities.contains { $0.id == city.id }
    }

    func add(_ city: City) {
        guard !contains(city) else { return }
        cities.append(city)
    }

    func remove(_ city: City) {
        cities.removeAll { $0.id == city.id }
    }

    func toggle(_ city: City) {
        if contains(city) { remove(city) } else { add(city) }
    }

    func addObserver(_ owner: AnyObject, block: @escaping ([City]) -> Void) {
        observers.removeAll { $0.owner === owner || $0.owner == nil }
        observers.append(Observer(owner: owner, block: block))
    }

    func removeObserver(_ owner: AnyObject) {
        observers.removeAll { $0.owner === owner || $0.owner == nil }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cities) {
            defaults.set(data, forKey: key)
        }
    }

    private func notify() {
        observers.removeAll { $0.owner == nil }
        let snapshot = cities
        observers.forEach { $0.block(snapshot) }
    }
}
