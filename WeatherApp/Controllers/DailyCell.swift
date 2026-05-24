import UIKit

final class DailyCell: UITableViewCell {

    static let reuseID = String(describing: DailyCell.self)

    private let dayLabel = UILabel()
    private let iconView = UIImageView()
    private let lowLabel = UILabel()
    private let highLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        dayLabel.font = .systemFont(ofSize: 17, weight: .medium)
        dayLabel.textColor = .white

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

        lowLabel.font = .systemFont(ofSize: 16, weight: .regular)
        lowLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        lowLabel.textAlignment = .right

        highLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        highLabel.textColor = .white
        highLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [dayLabel, iconView, lowLabel, highLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        dayLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            lowLabel.widthAnchor.constraint(equalToConstant: 44),
            highLabel.widthAnchor.constraint(equalToConstant: 44),
        ])
    }

    func configure(dayText: String, code: Int, low: Double, high: Double) {
        dayLabel.text = dayText
        iconView.image = UIImage(systemName: WeatherCode.symbolName(for: code))
        lowLabel.text = "\(Int(low.rounded()))°"
        highLabel.text = "\(Int(high.rounded()))°"
    }
}
