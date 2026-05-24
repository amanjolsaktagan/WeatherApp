import UIKit

final class CityCell: UITableViewCell {

    static let reuseID = String(describing: CityCell.self)

    private let card = GradientView(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1, y: 1))
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tempLabel = UILabel()
    private let highLowLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.85)
        subtitleLabel.numberOfLines = 1

        tempLabel.font = .systemFont(ofSize: 44, weight: .thin)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .right
        tempLabel.setContentHuggingPriority(.required, for: .horizontal)
        tempLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        highLowLabel.font = .systemFont(ofSize: 13, weight: .regular)
        highLowLabel.textColor = .white.withAlphaComponent(0.85)
        highLowLabel.textAlignment = .right

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let leftStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 2
        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let tempStack = UIStackView(arrangedSubviews: [tempLabel, highLowLabel])
        tempStack.axis = .vertical
        tempStack.alignment = .trailing
        tempStack.spacing = 0

        let rightGroup = UIStackView(arrangedSubviews: [iconView, tempStack])
        rightGroup.axis = .horizontal
        rightGroup.alignment = .center
        rightGroup.spacing = 10
        rightGroup.setContentHuggingPriority(.required, for: .horizontal)
        rightGroup.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [leftStack, rightGroup])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    func configure(
        title: String,
        subtitle: String,
        snapshot: CityListViewModel.WeatherSnapshot
    ) {
        nameLabel.text = title
        subtitleLabel.text = subtitle
        card.apply(WeatherTheme.palette(for: snapshot.weatherCode))

        if let code = snapshot.weatherCode {
            iconView.image = UIImage(systemName: WeatherCode.symbolName(for: code))
            iconView.tintColor = .white
        } else {
            iconView.image = UIImage(systemName: "ellipsis")
            iconView.tintColor = UIColor.white.withAlphaComponent(0.5)
        }
        tempLabel.text = snapshot.temperatureCelsius.map { "\(Int($0.rounded()))°" } ?? "—"
        if let hi = snapshot.dailyHigh, let lo = snapshot.dailyLow {
            highLowLabel.text = "H:\(Int(hi.rounded()))°  L:\(Int(lo.rounded()))°"
        } else {
            highLowLabel.text = " "
        }
    }
}
