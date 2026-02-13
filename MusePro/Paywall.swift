//
//  Paywall.swift
//  MusePro
//
//  Created by Omer Karisman on 12.02.24.
//

import Foundation
import SwiftUI
import RevenueCat

struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

class PaywallManager: ObservableObject {
    static let shared = PaywallManager()
    var userManager = UserManager.shared
    @Published var showModal: Bool = false
    @Published var showSheet: Bool = false
    
    func presentPaywall(force: Bool = false) {
        guard userManager.subscription == .none || force else { return }
        AnalyticsUtil.logEvent("musepro_present_paywall")

        if UIDevice.isIPhone {
            withAnimation {
                showSheet = true
            }
        } else {
            withAnimation {
                showModal = true
            }
        }
    }
    
    
    func dismissPaywall() {
        if UIDevice.isIPhone {
            withAnimation {
                showSheet = false
            }
        } else {
            withAnimation {
                showModal = false
            }
        }
    }
}

extension Date: RawRepresentable {
    public var rawValue: String {
        self.timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

enum PaywallRequest {
    @AppStorage("lastPaywallRequestDate") static var lastPaywallRequestDate: Date?
    static let limitInDays = UserManager.shared.remoteConfig?.configValue(forKey: "museProPaywallLimit").numberValue.intValue ?? 10
    
    static func presentPaywall() {
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        guard let lastDate = lastPaywallRequestDate else {
            lastPaywallRequestDate = currentDate
            return
        }
        
        let daysSinceLastRequest = calendar.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0
        guard daysSinceLastRequest >= limitInDays else { return }
        
        lastPaywallRequestDate = currentDate
        
        PaywallManager.shared.presentPaywall()
    }
    
}


struct PaywallView: View {
    @ObservedObject var userManager = UserManager.shared
    @State var tab: Int = 1
    func priceFormatter(package: Package) -> String {
        let formattedPrice: String
       
        if let introDiscount = package.storeProduct.introductoryDiscount {
//           let discountPrice = introDiscount.price
//           let discountPeriodValue = introDiscount.subscriptionPeriod.value
//           let discountPeriodUnit = introDiscount.subscriptionPeriod.unit
            let period = introDiscount.subscriptionPeriod.unit == .week ? "week" : "month"
            formattedPrice = "\(introDiscount.localizedPriceString) /\(period)*"
        } else {
            let period = package.storeProduct.subscriptionPeriod?.unit == .week ? "week" : "month"
            formattedPrice = "\(package.localizedPriceString) /\(period)"
        }
        return formattedPrice
    }
    
    var body: some View {
        VStack {
            
            Image("SubscriptionHero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(alignment: .center)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Picker(selection: $tab, label: Text("")) {
               Text("Weekly").tag(1)
               Text("Monthly").tag(2)
           }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            Spacer()
            VStack (alignment: .leading) {
                Text("Everything you need to break through creative blocks and elevate your creativity.")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(Color.paywallText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            Spacer()
            VStack {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 20, weight: .light))

                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(8)
                    VStack (alignment: .leading) {
                        Text("Realtime generation")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                            .foregroundStyle(Color.paywallText)
                        Text("See your artwork evolve as you draw")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                }
                HStack {
                    Image(systemName: "eye")
                        .font(.system(size: 20, weight: .light))

                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(8)
                    VStack (alignment: .leading) {
                        Text("Vision: Image to Prompt")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Prompts influenced by your drawings")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                }
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .light))

                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(8)
                    VStack (alignment: .leading) {
                        Text("Image Enhancer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Add detail and quality in seconds")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                }
                HStack {
                    Image(systemName: "text.redaction")
                        .font(.system(size: 20, weight: .light))

                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(UIColor.systemBlue))
                        .padding(8)
                    VStack (alignment: .leading) {
                        Text("Prompt Enhancer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Expand ideas with a tap")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.paywallText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom)
            Spacer()
            if tab == 1 {
                VStack {
                    if let offering = userManager.currentOffering, let package = offering.weekly {
                        
                        Button {
                            Purchases.shared.purchase(package: package) { transaction, customerInfo, error, cancelled in
                                if error == nil, let customerInfo {
                                    if customerInfo.entitlements["Pro"]?.isActive == true {
                                        UserManager.shared.subscription = .pro
                                        AnalyticsUtil.logEvent("musepro_purchase")
                                    }
                                    withAnimation {
                                        PaywallManager.shared.dismissPaywall()
                                    }
                                } else {
                                    ToastManager.shared.showError(message: "Subscription Error")
                                }
                            }
                        } label: {
                            VStack {
                                Text("Subscribe for")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.paywallTextAlt)
                                
                                Text(priceFormatter(package: package))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .disabled(true)
                                    .foregroundStyle(Color.paywallBackground)
                                
                            }
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 36)
                                    .fill(Color.paywallText)
                            }
                        }
                        
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        if let discount = package.storeProduct.introductoryDiscount {
                            let discountPrice = discount.price
                            let discountPeriodValue = discount.subscriptionPeriod.value
                            let discountPeriodUnit = discount.subscriptionPeriod.unit
                            let discountValid = discount.numberOfPeriods
                            let period = discountPeriodUnit == .week ? "week" : "month"
                            let fullPrice = "\(package.localizedPriceString) /\(period)"
                            Text("*Special discount renews at \(fullPrice) after \(discountValid) \(discountPeriodUnit)(s).")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Color.paywallText)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        VStack {
                            Text("Subscribe for")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.paywallTextAlt)
                            //                                    Text(priceFormatter(package: offering.package(identifier: "Monthly Basic")!))
                            
                            Text("Loading Package...")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .disabled(true)
                                .foregroundStyle(Color.paywallBackground)
                            
                        }
                        .padding()
                        .frame(height: 72)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 36)
                                .fill(Color.paywallText)
                        }
                        .padding()
                    }
                }.tag(1)
            } else {
                VStack {
                    if let offering = userManager.currentOffering, let package = offering.monthly {
                       
                        Button {
                            Purchases.shared.purchase(package: package) { transaction, customerInfo, error, cancelled in
                                if error == nil, let customerInfo {
                                    if customerInfo.entitlements["Pro"]?.isActive == true {
                                        UserManager.shared.subscription = .pro
                                        AnalyticsUtil.logEvent("musepro_purchase")
                                    }
                                    withAnimation {
                                        PaywallManager.shared.dismissPaywall()
                                    }
                                } else {
                                    ToastManager.shared.showError(message: "Subscription Error")
                                }
                            }
                        } label: {
                            VStack {
                                Text("Subscribe for")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.paywallTextAlt)
                                
                                Text(priceFormatter(package: package))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .disabled(true)
                                    .foregroundStyle(Color.paywallBackground)
                                
                            }
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 36)
                                    .fill(Color.paywallText)
                            }
                        }
                        
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        if let discount = package.storeProduct.introductoryDiscount {
                            let discountPrice = discount.price
                            let discountPeriodValue = discount.subscriptionPeriod.value
                            let discountPeriodUnit = discount.subscriptionPeriod.unit
                            let discountValid = discount.numberOfPeriods
                            let fullPrice = "\(package.localizedPriceString) / Month"
                            Text("*Special discount renews at \(fullPrice) after \(discountValid) \(discountPeriodUnit)(s).")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Color.paywallText)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        VStack {
                            Text("Subscribe for")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.paywallTextAlt)
                            //                                    Text(priceFormatter(package: offering.package(identifier: "Monthly Basic")!))
                            
                            Text("Loading Package...")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .disabled(true)
                                .foregroundStyle(Color.paywallBackground)
                            
                        }
                        .padding()
                        .frame(height: 72)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 36)
                                .fill(Color.paywallText)
                        }
                        .padding()
                    }
                }.tag(2)
            }
            Spacer()

            Button {
                Purchases.shared.restorePurchases { customerInfo, error in
                    if error == nil{
                        if let ci = customerInfo {
                            if ci.entitlements["Pro"]?.isActive == true {
                                UserManager.shared.subscription = .pro
                            }
                        } else {
                            ToastManager.shared.showError(message: "Restore Error")
                        }
                    } else {
                        ToastManager.shared.showError(message: "Restore Error")
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.paywallTextAlt2)
                //
            }
            .padding(8)
        }
    }
}

#Preview {
    VStack {
        
    }.sheet(isPresented: .constant(true), content: {
        PaywallView()
    })
}
