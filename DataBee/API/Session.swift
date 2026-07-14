//
//  Session.swift
//  DataBee
//

import Foundation

/// Stores the authenticated company and user for the current session.
final class Session {

    static let shared = Session()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let accessToken = "session.accessToken"
        static let companyCode = "session.companyCode"
        static let companyName = "session.companyName"
        static let currentUser = "session.currentUser"
        static let userName = "session.userName"
        static let password = "session.password"
    }

    /// Company code was exchanged for a token at least once → skip Company Auth.
    var isCompanyAuthenticated: Bool { accessToken != nil }

    /// A user is logged in → go straight to the chat screen.
    var isLoggedIn: Bool { currentUser != nil }

    /// Database name the AI query API expects, mirroring the web's DB_MAP:
    /// tnr → TurnerAI_DB, act → AshleyHS-CT, rcr → RoomConcept_DB.
    /// Resolved from the authenticated company's name; Ashley is the default.
    var dbName: String {
        let name = (companyName ?? "").lowercased()
        if name.contains("turner") { return "TurnerAI_DB" }
        if name.contains("room") { return "RoomConcept_DB" }
        return "AshleyHS-CT"
    }

    var accessToken: String? {
        get { defaults.string(forKey: Keys.accessToken) }
        set { defaults.set(newValue, forKey: Keys.accessToken) }
    }

    /// The company code the user last authenticated with (pre-filled on the auth screen).
    var companyCode: String? {
        get { defaults.string(forKey: Keys.companyCode) }
        set { defaults.set(newValue, forKey: Keys.companyCode) }
    }

    var companyName: String? {
        get { defaults.string(forKey: Keys.companyName) }
        set { defaults.set(newValue, forKey: Keys.companyName) }
    }

    /// Last successful login credentials (pre-filled on the login screen).
    var userName: String? {
        get { defaults.string(forKey: Keys.userName) }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    var password: String? {
        get { defaults.string(forKey: Keys.password) }
        set { defaults.set(newValue, forKey: Keys.password) }
    }

    var currentUser: LoginUser? {
        get {
            guard let data = defaults.data(forKey: Keys.currentUser) else { return nil }
            return try? JSONDecoder().decode(LoginUser.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.currentUser)
            } else {
                defaults.removeObject(forKey: Keys.currentUser)
            }
        }
    }

    /// Logout keeps the company authentication and the saved credentials
    /// (so the login screen is pre-filled), and only forgets the logged-in user.
    func logout() {
        currentUser = nil
    }
}
