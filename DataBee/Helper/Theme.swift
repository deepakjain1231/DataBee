//
//  Theme.swift
//  DataBee
//

import UIKit

enum Theme {

    // MARK: - Brand Colors

    static let orange = UIColor(red: 247/255, green: 144/255, blue: 44/255, alpha: 1)   // #F7902C
    static let teal = UIColor(red: 16/255, green: 121/255, blue: 151/255, alpha: 1)     // #107997
    static let gradientTop = UIColor(red: 0.894, green: 0.929, blue: 0.937, alpha: 1)
    static let gradientBottom = UIColor(red: 0.961, green: 0.941, blue: 0.918, alpha: 1)
    static let fieldIcon = UIColor(white: 0.68, alpha: 1)
    static let fieldBorder = UIColor(white: 0.86, alpha: 1)
    static let placeholderText = UIColor(white: 0.72, alpha: 1)

    // MARK: - Fonts

    static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Regular", size: size) ?? .systemFont(ofSize: size)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Medium", size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }

    static func semiBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }

    static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Bold", size: size) ?? .boldSystemFont(ofSize: size)
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }
}

// MARK: - Gradient Background

final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [Theme.gradientTop.cgColor, Theme.gradientBottom.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

// MARK: - Reusable Controls

enum ThemeFactory {

    static func cardView() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 1, alpha: 0.75)
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        return card
    }

    static func titleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Theme.semiBold(20)
        label.textColor = Theme.teal
        label.textAlignment = .center
        return label
    }

    static func filledButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Theme.semiBold(18)
        button.backgroundColor = color
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    /// A rounded bordered container holding a leading icon and a text field.
    static func iconTextField(placeholder: String, systemImage: String, isSecure: Bool = false) -> (container: UIView, textField: UITextField) {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.fieldBorder.cgColor
        container.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let icon = UIImageView(image: UIImage(systemName: systemImage))
        icon.tintColor = Theme.fieldIcon
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let textField = UITextField()
        textField.font = Theme.medium(18)
        textField.textColor = .darkText
        textField.isSecureTextEntry = isSecure
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: Theme.placeholderText, .font: Theme.medium(18)]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(icon)
        container.addSubview(textField)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 26),
            icon.heightAnchor.constraint(equalToConstant: 26),

            textField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: container.topAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return (container, textField)
    }
}
