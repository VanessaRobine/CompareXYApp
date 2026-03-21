import StoreKit
import SwiftUI
import Combine

class PurchaseManager: ObservableObject {

    static let shared = PurchaseManager()

    let unlimitedProductID = "com.vanessadestaingrobine.Compare.unlimited"

    @Published var isUnlimited: Bool = false
    @Published var products: [Product] = []
    @Published var isPurchasing: Bool = false

    private let dailyCountKey = "dailyComparisonCount"
    private let lastResetDateKey = "lastResetDate"
    private let installDateKey = "installDate"

    let firstDayLimit = 5
    
    let regularDailyLimit = 5

    // MARK: - Computed limits

    var isFirstDay: Bool {
        let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date ?? Date()
        return Calendar.current.isDateInToday(installDate)
    }

    var freeLimit: Int {
        isFirstDay ? firstDayLimit : regularDailyLimit
    }

    var dailyCount: Int {
        get { UserDefaults.standard.integer(forKey: dailyCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: dailyCountKey) }
    }

    var canCompare: Bool {
        isUnlimited || dailyCount < freeLimit
    }

    var comparisonsRemaining: Int {
        isUnlimited ? Int.max : max(0, freeLimit - dailyCount)
    }

    // MARK: - Init

    init() {
        saveInstallDateIfNeeded()
        checkAndResetDailyCount()
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }

    // MARK: - Install date

    private func saveInstallDateIfNeeded() {
        if UserDefaults.standard.object(forKey: installDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
        }
    }

    // MARK: - Daily reset

    func incrementDailyCount() {
        dailyCount += 1
    }
    func addBonusComparison() {
        if dailyCount > 0 {
            dailyCount -= 1
        }
    }
    private func checkAndResetDailyCount() {
        let lastReset = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            dailyCount = 0
            UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        }
    }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            products = try await Product.products(for: [unlimitedProductID])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == unlimitedProductID {
                    await MainActor.run { isUnlimited = true }
                }
            }
        }
    }

    func purchase() async {
        guard let product = products.first else { return }
        await MainActor.run { isPurchasing = true }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await MainActor.run { isUnlimited = true }
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        await MainActor.run { isPurchasing = false }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }
}
