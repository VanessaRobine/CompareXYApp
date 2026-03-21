//
//  UsageManager.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/6/26.
//
import Foundation
import Combine

class UsageManager: ObservableObject {
    
    @Published var comparisonsToday: Int = 0
    @Published var isPremium: Bool = false
    
    let freeLimit = 5
    
    var remainingComparisons: Int {
        isPremium ? 999 : max(0, freeLimit - comparisonsToday)
    }
    
    var hasReachedLimit: Bool {
        !isPremium && comparisonsToday >= freeLimit
    }
    
    init() {
        
        loadUsage()
    }
    
    func useComparison() {
        guard !hasReachedLimit else { return }
        comparisonsToday += 1
        saveUsage()
    }
    
    func unlockExtraComparisons(_ count: Int = 5) {
        comparisonsToday = max(0, comparisonsToday - count)
        saveUsage()
    }
    
    func unlockPremium() {
        isPremium = true
        UserDefaults.standard.set(true, forKey: "isPremium")
    }
    
    private func saveUsage() {
        UserDefaults.standard.set(comparisonsToday, forKey: "comparisonsToday")
        UserDefaults.standard.set(Date(), forKey: "lastUseDate")
    }
    
    private func loadUsage() {
        isPremium = true  // Free for all users — remove when adding paywall
        return
        
        // ---- Everything below runs in production only ----
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        
        let lastDate = UserDefaults.standard.object(forKey: "lastUseDate") as? Date
        
        if let lastDate = lastDate, Calendar.current.isDateInToday(lastDate) {
            comparisonsToday = UserDefaults.standard.integer(forKey: "comparisonsToday")
        } else {
            // New day or first launch — reset count
            comparisonsToday = 0
            saveUsage()
        }
    }
    
    // Call this during development only — never in production
    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: "comparisonsToday")
        UserDefaults.standard.removeObject(forKey: "lastUseDate")
        UserDefaults.standard.removeObject(forKey: "isPremium")
        comparisonsToday = 0
        isPremium = false
    }
}
