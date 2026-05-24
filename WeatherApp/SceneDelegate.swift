import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let viewModel = CityListViewModel(
            weatherService: WeatherService(),
            favoritesStore: FavoritesStore.shared,
            locationService: LocationService()
        )
        let listVC = CityListViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: listVC)
        nav.navigationBar.prefersLargeTitles = true

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
