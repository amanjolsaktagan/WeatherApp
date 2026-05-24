import UIKit

final class CityDetailViewController: UIViewController {

    private let viewModel: CityDetailViewModel

    // Background gradient (whole-page) — re-applied whenever the weather code changes.
    private let backgroundView = GradientView(
        start: CGPoint(x: 0.5, y: 0),
        end:   CGPoint(x: 0.5, y: 1)
    )

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Header
    private let cityLabel = UILabel()
    private let headerIconView = UIImageView()
    private let tempLabel = UILabel()
    private let conditionLabel = UILabel()
    private let highLowLabel = UILabel()

    // Hourly
    private lazy var hourlyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 96)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(HourlyCell.self, forCellWithReuseIdentifier: HourlyCell.reuseID)
        cv.dataSource = self
        return cv
    }()

    // Daily
    private lazy var dailyTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(DailyCell.self, forCellReuseIdentifier: DailyCell.reuseID)
        tv.dataSource = self
        tv.isScrollEnabled = false
        tv.rowHeight = 48
        return tv
    }()
    private var dailyTableHeightConstraint: NSLayoutConstraint!

    private lazy var favoriteButton = UIBarButtonItem(
        image: nil, style: .plain, target: self, action: #selector(toggleFavorite)
    )

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    init(viewModel: CityDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.city.name
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = favoriteButton

        setupBackground()
        setupNavigationAppearance()
        setupLayout()
        bindViewModel()
        render()

        Task { [weak self] in await self?.viewModel.load() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .white
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = nil
    }

    // MARK: Setup

    private func setupBackground() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.apply(WeatherTheme.palette(for: nil))
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(makeSectionCard(title: "Hourly forecast", content: hourlyCollectionView))
        contentStack.addArrangedSubview(makeSectionCard(title: "7-day forecast", content: dailyTableView))

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        contentStack.addArrangedSubview(errorLabel)
    }

    private func makeHeader() -> UIView {
        cityLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        cityLabel.textAlignment = .center
        cityLabel.textColor = .white
        cityLabel.text = viewModel.city.name

        headerIconView.tintColor = .white
        headerIconView.contentMode = .scaleAspectFit
        headerIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .light)
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        headerIconView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        tempLabel.font = .systemFont(ofSize: 88, weight: .thin)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center

        conditionLabel.font = .systemFont(ofSize: 18, weight: .medium)
        conditionLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        conditionLabel.textAlignment = .center

        highLowLabel.font = .systemFont(ofSize: 15, weight: .regular)
        highLowLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        highLowLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            cityLabel, headerIconView, tempLabel, conditionLabel, highLowLabel,
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.setCustomSpacing(8, after: cityLabel)
        stack.setCustomSpacing(0, after: headerIconView)
        stack.setCustomSpacing(6, after: tempLabel)
        return stack
    }

    private func makeSectionCard(title: String, content: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor

        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        separator.translatesAutoresizingMaskIntoConstraints = false

        content.translatesAutoresizingMaskIntoConstraints = false
        if let cv = content as? UICollectionView {
            cv.heightAnchor.constraint(equalToConstant: 110).isActive = true
        }
        if content === dailyTableView {
            dailyTableHeightConstraint = content.heightAnchor.constraint(equalToConstant: 0)
            dailyTableHeightConstraint.isActive = true
        }

        card.addSubview(titleLabel)
        card.addSubview(separator)
        card.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            content.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
        ])

        return card
    }

    private func bindViewModel() {
        viewModel.onChange = { [weak self] in self?.render() }
    }

    // MARK: Render

    private func render() {
        updateFavoriteIcon()

        if viewModel.isLoading { activityIndicator.startAnimating() }
        else { activityIndicator.stopAnimating() }

        errorLabel.isHidden = viewModel.errorMessage == nil
        errorLabel.text = viewModel.errorMessage

        guard let weather = viewModel.weather else {
            tempLabel.text = "—"
            conditionLabel.text = " "
            highLowLabel.text = " "
            headerIconView.image = nil
            return
        }

        backgroundView.apply(WeatherTheme.palette(for: weather.current.weatherCode))
        tempLabel.text = "\(Int(weather.current.temperature2m.rounded()))°"
        conditionLabel.text = WeatherCode.description(for: weather.current.weatherCode)
        headerIconView.image = UIImage(systemName: WeatherCode.symbolName(for: weather.current.weatherCode))

        if let hi = weather.daily.temperature2mMax.first,
           let lo = weather.daily.temperature2mMin.first {
            highLowLabel.text = "H:\(Int(hi.rounded()))°   L:\(Int(lo.rounded()))°"
        }

        hourlyCollectionView.reloadData()
        dailyTableView.reloadData()
        dailyTableHeightConstraint.constant = CGFloat(weather.daily.time.count) * dailyTableView.rowHeight
    }

    private func updateFavoriteIcon() {
        let name = viewModel.isFavorite ? "star.fill" : "star"
        favoriteButton.image = UIImage(systemName: name)
        favoriteButton.tintColor = viewModel.isFavorite ? .systemYellow : .white
    }

    @objc private func toggleFavorite() {
        viewModel.toggleFavorite()
    }
}

// MARK: - Hourly

extension CityDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let weather = viewModel.weather else { return 0 }
        return min(24, weather.hourly.time.count)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyCell.reuseID, for: indexPath) as! HourlyCell
        guard let weather = viewModel.weather else { return cell }
        let startIndex = Self.startingHourlyIndex(for: weather)
        let i = startIndex + indexPath.item
        guard weather.hourly.time.indices.contains(i) else { return cell }
        cell.configure(
            hourText: Self.hourLabel(from: weather.hourly.time[i], isFirst: indexPath.item == 0),
            code: weather.hourly.weatherCode[i],
            temperature: weather.hourly.temperature2m[i]
        )
        return cell
    }

    private static func startingHourlyIndex(for weather: Weather) -> Int {
        let nowPrefix = String(weather.current.time.prefix(13)) // YYYY-MM-DDTHH
        return weather.hourly.time.firstIndex(where: { $0.hasPrefix(nowPrefix) }) ?? 0
    }

    private static func hourLabel(from isoTime: String, isFirst: Bool) -> String {
        if isFirst { return "Now" }
        let parts = isoTime.split(separator: "T")
        guard parts.count == 2 else { return isoTime }
        let hh = parts[1].split(separator: ":").first.map(String.init) ?? ""
        return "\(hh):00"
    }
}

// MARK: - Daily

extension CityDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.weather?.daily.time.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DailyCell.reuseID, for: indexPath) as! DailyCell
        let weather = viewModel.weather!
        cell.configure(
            dayText: Self.dayLabel(from: weather.daily.time[indexPath.row], isFirst: indexPath.row == 0),
            code: weather.daily.weatherCode[indexPath.row],
            low: weather.daily.temperature2mMin[indexPath.row],
            high: weather.daily.temperature2mMax[indexPath.row]
        )
        return cell
    }

    private static func dayLabel(from isoDate: String, isFirst: Bool) -> String {
        if isFirst { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: isoDate) else { return isoDate }
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "EEEE"
        return outFormatter.string(from: date)
    }
}
