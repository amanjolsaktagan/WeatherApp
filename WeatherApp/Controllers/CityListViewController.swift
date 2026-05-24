import UIKit

final class CityListViewController: UIViewController {

    private enum FavoritesSection: Int, CaseIterable {
        case currentLocation
        case favorites
    }

    private let viewModel: CityListViewModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()

    init(viewModel: CityListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Weather"
        navigationItem.largeTitleDisplayMode = .always

        setupSearch()
        setupTable()
        bindViewModel()

        Task { [weak self] in await self?.viewModel.refreshAll() }
    }

    // MARK: Setup

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search for a city"
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CityCell.self, forCellReuseIdentifier: CityCell.reuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.onChange = { [weak self] in self?.tableView.reloadData() }
    }

    @objc private func handleRefresh() {
        Task { [weak self] in
            await self?.viewModel.refreshAll()
            self?.refreshControl.endRefreshing()
        }
    }

    // MARK: Navigation

    private func openDetail(for city: City) {
        let detailVM = CityDetailViewModel(
            city: city,
            weatherService: WeatherService(),
            favoritesStore: FavoritesStore.shared
        )
        let detailVC = CityDetailViewController(viewModel: detailVM)
        // Don't dismiss the search controller here — setting isActive=false starts
        // a dismissal transition that races the navigation push and silently
        // swallows it. Resigning the keyboard is enough; the search bar stays
        // attached to this VC and is restored when we pop back.
        searchController.searchBar.resignFirstResponder()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension CityListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.mode == .favorites ? FavoritesSection.allCases.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.mode {
        case .search:
            return viewModel.searchResults.count
        case .favorites:
            switch FavoritesSection(rawValue: section) {
            case .currentLocation: return viewModel.currentLocation == nil ? 0 : 1
            case .favorites:       return viewModel.favorites.count
            case .none:            return 0
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard viewModel.mode == .favorites else { return nil }
        switch FavoritesSection(rawValue: section) {
        case .currentLocation: return viewModel.currentLocation == nil ? nil : "Current Location"
        case .favorites:       return viewModel.favorites.isEmpty ? nil : "Favorites"
        case .none:            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.mode {
        case .search:
            return searchCell(for: indexPath)
        case .favorites:
            switch FavoritesSection(rawValue: indexPath.section) {
            case .currentLocation:
                let row = viewModel.currentLocation!
                let cell = tableView.dequeueReusableCell(withIdentifier: CityCell.reuseID, for: indexPath) as! CityCell
                cell.configure(
                    title: row.place.name,
                    subtitle: "My Location",
                    snapshot: row.snapshot
                )
                return cell
            case .favorites:
                let row = viewModel.favorites[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: CityCell.reuseID, for: indexPath) as! CityCell
                cell.configure(
                    title: row.city.name,
                    subtitle: row.snapshot.weatherCode.map { WeatherCode.description(for: $0) } ?? "Loading…",
                    snapshot: row.snapshot
                )
                return cell
            case .none:
                return UITableViewCell()
            }
        }
    }

    private func searchCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        let city = viewModel.searchResults[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = city.name
        config.secondaryText = city.subtitle
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.mode == .favorites ? 100 : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch viewModel.mode {
        case .search:
            openDetail(for: viewModel.searchResults[indexPath.row])
        case .favorites:
            switch FavoritesSection(rawValue: indexPath.section) {
            case .currentLocation:
                if let row = viewModel.currentLocation { openDetail(for: row.place.asCity()) }
            case .favorites:
                openDetail(for: viewModel.favorites[indexPath.row].city)
            case .none:
                break
            }
        }
    }
}

// MARK: - UISearchResultsUpdating

extension CityListViewController: UISearchResultsUpdating, UISearchBarDelegate {

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearch(query: searchController.searchBar.text ?? "")
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.cancelSearch()
    }
}
