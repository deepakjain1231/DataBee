//
//  SplashViewController.swift
//  DataBee
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let logoImageView = UIImageView(image: UIImage(named: "ic_logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 225),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor, multiplier: 516.0 / 1011.0)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showNextScreen()
        }
    }

    /// Routes based on what is saved locally:
    /// logged in → chat, company authenticated → login, otherwise → company auth.
    private func showNextScreen() {
        guard let window = view.window else { return }

        let session = Session.shared
        let navigationController: UINavigationController
        if session.isLoggedIn {
            navigationController = UINavigationController(rootViewController: ChatViewController())
        } else if session.isCompanyAuthenticated {
            // Keep Company Auth beneath Login so Cancel/back still works.
            navigationController = UINavigationController(rootViewController: CompanyAuthViewController())
            navigationController.viewControllers = [CompanyAuthViewController(), LoginViewController()]
        } else {
            navigationController = UINavigationController(rootViewController: CompanyAuthViewController())
        }
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}
