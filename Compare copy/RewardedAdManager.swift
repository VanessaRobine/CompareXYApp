//
//  RewardedAdManager.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/17/26.
//

import Foundation
import SwiftUI
import Combine

class RewardedAdManager: NSObject, ObservableObject {
    static let shared = RewardedAdManager()
    @Published var isAdReady = false
    
    func loadAd() {}
    func showAd(from viewController: UIViewController, onRewarded: @escaping () -> Void) {}
}
