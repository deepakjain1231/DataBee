//
//  CompanyAuthViewController.swift
//  DataBee
//

import UIKit

class CompanyAuthViewController: BaseAuthViewController {

    private var companyCodeTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = ThemeFactory.titleLabel("Authenticate")

        let field = ThemeFactory.iconTextField(placeholder: "Company Code", systemImage: "building.2.fill", isSecure: true)
        companyCodeTextField = field.textField
        companyCodeTextField.returnKeyType = .go
        companyCodeTextField.delegate = self
        companyCodeTextField.text = Session.shared.companyCode

        let authenticateButton = ThemeFactory.filledButton(title: "Authenticate", color: Theme.orange)
        authenticateButton.addTarget(self, action: #selector(tapOnAuthenticate), for: .touchUpInside)

        cardStack.addArrangedSubview(titleLabel)
        cardStack.setCustomSpacing(48, after: titleLabel)
        cardStack.addArrangedSubview(field.container)
        cardStack.setCustomSpacing(48, after: field.container)
        cardStack.addArrangedSubview(authenticateButton)
    }

    // MARK: - Actions

    @objc private func tapOnAuthenticate() {
        view.endEditing(true)
        guard validation() else { return }

        let code = (companyCodeTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        showLoading()
        Task {
            do {
                let token = try await APIClient.shared.authenticateCompany(code: code)
                Session.shared.accessToken = token.accessToken
                Session.shared.companyCode = code
                Session.shared.companyName = token.name
                Session.shared.userName = ""
                Session.shared.password = ""
                hideLoading()
                navigationController?.pushViewController(LoginViewController(), animated: true)
            } catch let error as APIError {
                hideLoading()
                switch error {
                case .noInternet:
                    showAlert(error.localizedDescription)
                default:
                    showAlert("Please enter valid company code.")
                }
            } catch {
                hideLoading()
                showAlert("Please enter valid company code.")
            }
        }
    }

    // MARK: - Validation

    private func validation() -> Bool {
        let code = (companyCodeTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if code.isEmpty {
            showAlert("Please Enter Company Code.")
            return false
        }
        return true
    }
}

extension CompanyAuthViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tapOnAuthenticate()
        return true
    }
}
