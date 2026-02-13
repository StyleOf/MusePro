//
//  AnalyticsManager.swift
//  MusePro
//
//  Created by Omer Karisman on 12.02.24.
//

import Foundation
import Firebase

#if os(visionOS)
   // visionOS code
#elseif os(iOS)
import Intercom
import FirebaseAnalytics
#endif
//import Intercom
//import Mixpanel

// NOTE: Please customize this file to send app events to Firebase Analytics.
struct AnalyticsUtil {
    static func logEvent(_ event: String) {
//#if DEBUG
//        print("Don't send events...")
//#else
//        Mixpanel.mainInstance().track(event: event, properties: [:])
#if os(visionOS)
   // visionOS code
#elseif os(iOS)
        Analytics.logEvent(event, parameters: nil)
        Intercom.logEvent(withName: event)
#endif
//        ApiService.shared.log(event: event, params: [:]) {
//
//        }
//#endif
    }
    
    static func logEvent(_ event: String, parameters: [String:String]) {
//#if DEBUG
//        print("Don't send events...")
//#else
//        Mixpanel.mainInstance().track(event: event, properties: parameters)
#if os(visionOS)
   // visionOS code
#elseif os(iOS)
        Analytics.logEvent(event, parameters: parameters)
        Intercom.logEvent(withName: event, metaData: parameters)
#endif
//        ApiService.shared.log(event: event, params: parameters) {
//
//        }
//#endif
    }
}
