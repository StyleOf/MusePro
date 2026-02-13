//
//  HunerApp.swift
//  Huner
//
//  Created by Omer Karisman on 04.12.23.
//

import SwiftUI
import FirebaseCore
import RevenueCat
#if os(visionOS)
   // visionOS code
#elseif os(iOS)
import Intercom
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        AnalyticsUtil.logEvent("musepro_app_open")
        _ = UserManager.shared
        #if os(visionOS)
           // visionOS code
        #elseif os(iOS)
                Intercom.setApiKey("YOUR_INTERCOM_API_KEY", forAppId:"YOUR_INTERCOM_APP_ID")
        #endif

        
//        Haptic.play(".---.---.--.--.-.-.-o-o-o-O-O-O-O-O-O-X-X-X-X-X-X-X-X-X-X-X-O-O-O-O-O-O-o-o-o-.-.-.--.--.---.---.---------------------------O------------X", delay: 0.008)
        #if os(visionOS)
        #elseif os(iOS)
                Haptic.play(".--o--O", delay: 0.05)
        #endif

        return true
    }
}

extension AppDelegate: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        if customerInfo.entitlements["Pro"]?.isActive == true {
            UserManager.shared.subscription = .pro
        }
    }
}

@main
struct MusePro: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
@ObservedObject var mainModel = MainModel.shared

  var body: some Scene {
    WindowGroup {
        MainMenu()
            .environmentObject(OrientationInfo())
    }
  }
}
