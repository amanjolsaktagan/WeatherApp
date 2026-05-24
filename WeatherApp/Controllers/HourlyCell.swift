import UIKit

final class HourlyCell: UICollectionViewCell {

    static let reuseID = String(describing: HourlyCell.self)

    private let hourLabel = UILabel()
    private let iconView = UIImageView()
    private let tempLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        hourLabel.font = .systemFont(ofSize: 13, weight: .medium)
        hourLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        hourLabel.textAlignment = .center

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

        tempLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [hourLabel, iconView, tempLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            iconView.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    func configure(hourText: String, code: Int, temperature: Double) {
        hourLabel.text = hourText
        iconView.image = UIImage(systemName: WeatherCode.symbolName(for: code))
        tempLabel.text = "\(Int(temperature.rounded()))°"
    }
}
