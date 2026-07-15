//
//  BaseAuthViewController.swift
//  DataBee
//

import UIKit
import SVProgressHUD

/// Shared layout for the authentication screens: gradient background,
/// logo + version header, and a rounded card that subclasses fill in.
class BaseAuthViewController: UIViewController {

    let scrollView = UIScrollView()
    let contentView = UIView()
    let logoImageView = UIImageView(image: UIImage(named: "ic_logo"))
    let versionLabel = UILabel()
    let cardView = ThemeFactory.cardView()
    let cardStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func buildLayout() {
        let background = GradientView()
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logoImageView)

        versionLabel.text = Theme.appVersion
        versionLabel.font = Theme.medium(15)
        versionLabel.textColor = Theme.teal
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(versionLabel)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        cardStack.axis = .vertical
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cardStack)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            logoImageView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 250),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 516.0 / 1011.0),

            versionLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: -4),
            versionLabel.trailingAnchor.constraint(equalTo: logoImageView.trailingAnchor),

            cardView.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 40),
            cardView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            // Fills the width on iPhone, but stays a centered panel on iPad.
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 540),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 44),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -44),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24)
        ])

        // Preferred full-width (minus margins) — gives way to the 540pt cap on iPad.
        let preferredWidth = cardView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
    }

    func showLoading() {
        SVProgressHUD.show()
    }

    func hideLoading() {
        SVProgressHUD.dismiss()
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "DataBee", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
