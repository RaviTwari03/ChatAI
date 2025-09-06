//
//  PurchaseManager.swift
//  Conversation AI
//
//  Created by Ravi Tiwari on 06/09/25.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: Configure your product identifiers from App Store Connect
    // Replace these with your real product IDs
    private let productIDs: [String] = [
        "c_ca_5900",   // Monthly or Yearly (as per ASC)
        "c_ca_699"     // Weekly
    ]

    // MARK: Published state for UI
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isSubscribed: Bool = false
    @Published var currentEntitlement: Product? = nil
    @Published var statusMessage: String = ""

    private var updatesTask: Task<Void, Never>? = nil

    private init() { }

    // Call from app launch
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = listenForTransactions()
        Task { await refreshProductsAndEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: Public API
    func refreshProductsAndEntitlements() async {
        do {
            try await fetchProducts()
            try await updateCurrentEntitlements()
        } catch {
            statusMessage = "Store error: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                try await updateCurrentEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                statusMessage = "Purchase pending approval"
                return false
            @unknown default:
                return false
            }
        } catch {
            statusMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            try await updateCurrentEntitlements()
            statusMessage = "Restored purchases"
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: Load products
    private func fetchProducts() async throws {
        let storeProducts = try await Product.products(for: productIDs)
        
        // Sort by price ascending for display with proper async handling
        var productsWithPrices: [(Product, Double)] = []
        
        for product in storeProducts {
            let price = await product.displayPriceDouble
            productsWithPrices.append((product, price))
        }
        
        self.products = productsWithPrices
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    // MARK: Entitlements
    private func updateCurrentEntitlements() async throws {
        var activeIDs: Set<String> = []
        var activeProduct: Product? = nil

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                activeIDs.insert(transaction.productID)
                if let match = products.first(where: { $0.id == transaction.productID }) {
                    // Prefer the highest-priced product as the active one when multiple exist
                    if let current = activeProduct {
                        let matchPrice = await match.displayPriceDouble
                        let currentPrice = await current.displayPriceDouble
                        activeProduct = (matchPrice > currentPrice) ? match : current
                    } else {
                        activeProduct = match
                    }
                }
            } catch {
                // Ignore unverified
            }
        }

        purchasedProductIDs = activeIDs
        currentEntitlement = activeProduct
        isSubscribed = !activeIDs.isEmpty
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(update)
                    await transaction?.finish()
                    await self?.refreshProductsAndEntitlements()
                } catch {
                    await MainActor.run { self?.statusMessage = "Transaction update failed" }
                }
            }
        }
    }

    // MARK: Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "IAP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Helpers
fileprivate extension Product {
    var displayPriceDouble: Double {
        get async {
            // Convert localized price to a numeric value for sorting; fall back to 0
            return Double(truncating: self.price as NSNumber)
        }
    }
}
