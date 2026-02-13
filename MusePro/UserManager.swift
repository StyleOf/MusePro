//
//  UserManager.swift
//  MusePro
//
//  Created by Omer Karisman on 12.02.24.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig
import FirebaseAuth
import RevenueCat
import SwiftUI
import Combine
#if os(visionOS)
   // visionOS code
#elseif os(iOS)
import Intercom
import FirebaseAnalytics
#endif

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    init(subscription: Subscription = .none, subscriptionIdentifier: String = "", remoteConfig: RemoteConfig? = nil) {
        self.subscription = subscription
        self.subscriptionIdentifier = subscriptionIdentifier
        self.remoteConfig = remoteConfig
        if let remainingOnboardingTokens = KeychainHelper.standard.read(key: "remainingOnboardingTokens", type: Int.self) {
            self.remainingOnboardingTokens = remainingOnboardingTokens
        } else {
            self.remainingOnboardingTokens = 0
        }
        
//        self.remainingOnboardingTokens = 100000

        if self.remainingOnboardingTokens > 0 {
            if self.subscription == .none {
                self.subscription = .trial
            }
        }
        
        self.onboardingComplete = KeychainHelper.standard.read(key: "onboardingComplete", type: Bool.self) ?? false
        
        Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
        Purchases.logLevel = .debug
        
        Auth.auth().signInAnonymously { authResult, error in
            guard let user = authResult?.user else {
            #if os(visionOS)
               // visionOS code
            #elseif os(iOS)
                Intercom.loginUnidentifiedUser()
            #endif
                return
            }
            
//            let isAnonymous = user.isAnonymous  // true
            self.uid = user.uid
            
            let attributes = ICMUserAttributes()
            attributes.userId = user.uid
            #if os(visionOS)
               // visionOS code
            #elseif os(iOS)
                Intercom.loginUser(with: attributes)
            #endif
            Purchases.shared.logIn(user.uid) { customerInfo, created, error in
                if error == nil, let customerInfo {
                    if customerInfo.entitlements["Pro"]?.isActive == true {
                        UserManager.shared.subscription = .pro
                    }
                }
            }
        }
        
        Purchases.shared.getOfferings { offerings, error in
            if error == nil {
                self.currentOffering = offerings?.current
            }
        }
        
        loadRemoteConfig()
    }
    
    enum Subscription{
        case none
        case trial
        case basic
        case pro
    }

    var uid: String = ""
    @Published var currentOffering: Offering? = nil
    @Published var subscription: Subscription = .none
    @Published var subscriptionIdentifier: String = ""
    @Published var onboardingComplete: Bool = false
    @Published var totalOnboardingTokens: Int = 0
    @Published var remainingOnboardingTokens: Int {
        didSet {
            debounce(interval: .seconds(1)) {
                KeychainHelper.standard.save(self.remainingOnboardingTokens, key: "remainingOnboardingTokens")
            }
            if remainingOnboardingTokens <= 0 {
                if subscription == .trial {
                    subscription = .none
                }
            } else {
                if subscription == .none {
                    subscription = .trial
                }
            }
        }
    }
    
    var task: Task<(), Never>?

    func debounce(interval: Duration = .nanoseconds(10000),
                  operation: @escaping () -> Void) {
        task?.cancel()

        task = Task {
            do {
                try await Task.sleep(for: interval)
                operation()
            } catch {
                // TODO
            }
        }
    }

    var remoteConfig: RemoteConfig?
    
    func spendOnboardingToken(n: Int = 1) -> Bool {
        if subscription == .trial && remainingOnboardingTokens - n >= 0 {
            DispatchQueue.main.async {
                self.remainingOnboardingTokens -= n
            }
            return true
        }
        return false
    }
    
    func canPerformPro(with tokens: Int) -> Bool {
        return subscription == .pro || spendOnboardingToken(n: tokens)
//        if !can {
//            PaywallRequest.presentPaywall()
//        }
//        return can
    }
    
    func loadRemoteConfig() {
        remoteConfig = RemoteConfig.remoteConfig()
        guard let remoteConfig else { return }
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        remoteConfig.fetch { (status, error) -> Void in
            if status == .success {
               
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
            
            remoteConfig.activate { changed, error in
                DispatchQueue.main.async {
                    self.totalOnboardingTokens = remoteConfig.configValue(forKey: "onboardingTokens").numberValue.intValue
                    if !self.onboardingComplete { //TODO: Fix
                        self.remainingOnboardingTokens = remoteConfig.configValue(forKey: "onboardingTokens").numberValue.intValue
                        self.onboardingComplete = true
                        KeychainHelper.standard.save(true, key: "onboardingComplete")
                        KeychainHelper.standard.save(self.remainingOnboardingTokens, key: "remainingOnboardingTokens")
                    }
                    if let falKey = remoteConfig.configValue(forKey: "falKey").stringValue {
                        ConnectionManager.shared.setupClient(with: falKey)
                    }
                }
            }
            
        }
    }
}
