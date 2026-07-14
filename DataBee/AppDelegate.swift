//
//  AppDelegate.swift
//  DataBee
//
//  Created by DEEPAK JAIN on 14/07/26.
//

import UIKit
import SVProgressHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureProgressHUD()
        return true
    }

    private func configureProgressHUD() {
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setBackgroundColor(.white)
        SVProgressHUD.setForegroundColor(Theme.teal)
        SVProgressHUD.setRingThickness(3)
        SVProgressHUD.setCornerRadius(14)
    }

}
