//
//  LoginViewController.swift
//  DataBee
//

import UIKit

class LoginViewController: BaseAuthViewController {

    private var userNameTextField: UITextField!
    private var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = ThemeFactory.titleLabel("Login Page")

        let userNameField = ThemeFactory.iconTextField(placeholder: "User Name", systemImage: "person.fill")
        userNameTextField = userNameField.textField
        userNameTextField.returnKeyType = .next
        userNameTextField.delegate = self
        userNameTextField.text = Session.shared.userName

        let passwordField = ThemeFactory.iconTextField(placeholder: "Password", systemImage: "lock.fill", isSecure: true)
        passwordTextField = passwordField.textField
        passwordTextField.returnKeyType = .go
        passwordTextField.delegate = self
        passwordTextField.text = Session.shared.password

        let loginButton = ThemeFactory.filledButton(title: "Login", color: Theme.teal)
        loginButton.addTarget(self, action: #selector(tapOnLogin), for: .touchUpInside)

        let cancelButton = ThemeFactory.filledButton(title: "Cancel", color: Theme.orange)
        cancelButton.addTarget(self, action: #selector(tapOnCancel), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [loginButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually

        cardStack.addArrangedSubview(titleLabel)
        cardStack.setCustomSpacing(40, after: titleLabel)
        cardStack.addArrangedSubview(userNameField.container)
        cardStack.setCustomSpacing(24, after: userNameField.container)
        cardStack.addArrangedSubview(passwordField.container)
        cardStack.setCustomSpacing(40, after: passwordField.container)
        cardStack.addArrangedSubview(buttonStack)
    }

    // MARK: - Actions

    @objc private func tapOnLogin() {
        view.endEditing(true)
        guard validation() else { return }

        let userName = (userNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text ?? ""
        showLoading()
        Task {
            do {
                let user = try await APIClient.shared.login(userName: userName, password: password)
                Session.shared.currentUser = user
                Session.shared.userName = userName
                Session.shared.password = password
                hideLoading()
                showChatScreen()
            } catch {
                hideLoading()
                showAlert(error.localizedDescription)
            }
        }
    }

    private func showChatScreen() {
        guard let window = view.window else { return }
        let navigationController = UINavigationController(rootViewController: ChatViewController())
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }

    @objc private func tapOnCancel() {
        userNameTextField.text = ""
        passwordTextField.text = ""
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Validation

    private func validation() -> Bool {
        if (userNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showAlert("Please Enter User Name.")
            return false
        }
        if (passwordTextField.text ?? "").isEmpty {
            showAlert("Please Enter Password.")
            return false
        }
        return true
    }
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userNameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            tapOnLogin()
        }
        return true
    }
}
