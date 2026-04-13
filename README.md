# Stubkit Swift SDK

Subscription validation for iOS, macOS, tvOS, watchOS, and visionOS — **3 lines of code**.

## Install

Add to your Xcode project via Swift Package Manager:

```
https://github.com/stubkithq/stubkit-swift
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/stubkithq/stubkit-swift", from: "1.0.0")
```

## Quick Start

```swift
import Stubkit

// 1. Configure (once, at app launch)
Stubkit.configure(apiKey: "pk_live_xxx", appId: "myapp")

// 2. Check entitlement
let isPro = try await Stubkit.shared.isActive(userId: "user_123", entitlement: "pro")

// 3. Sync purchase (after StoreKit 2 transaction)
let entitlements = try await Stubkit.shared.syncPurchase(
    userId: "user_123",
    platform: .ios,
    productId: "com.myapp.pro",
    receipt: transaction.jwsRepresentation
)
```

That's it. Three lines to validate subscriptions.

## StoreKit 2 Integration

```swift
import StoreKit
import Stubkit

func handlePurchase(_ result: VerificationResult<Transaction>) async throws {
    guard case .verified(let transaction) = result else { return }
    
    let entitlements = try await Stubkit.shared.syncPurchase(
        userId: currentUserId,
        platform: .ios,
        productId: transaction.productID,
        receipt: transaction.jwsRepresentation,
        transactionId: String(transaction.id)
    )
    
    await transaction.finish()
}
```

## API

### `Stubkit.configure(apiKey:appId:baseURL:)`
Initialize the SDK. Call once at app launch.

### `Stubkit.shared.isActive(userId:entitlement:) -> Bool`
Check if a user has an active entitlement. Returns `true` for `active`, `grace`, or `cancelled` (not yet expired).

### `Stubkit.shared.getEntitlements(userId:) -> [Entitlement]`
Get all entitlements for a user.

### `Stubkit.shared.syncPurchase(userId:platform:productId:receipt:transactionId:) -> [Entitlement]`
Submit a purchase receipt for validation. Returns updated entitlements.

### `Stubkit.shared.refresh(userId:) -> [Entitlement]`
Force refresh entitlements (bypass server cache).

## Requirements

- iOS 15+ / macOS 12+ / tvOS 15+ / watchOS 8+ / visionOS 1+
- Swift 5.9+
- Xcode 15+

## Links

- [Documentation](https://docs.stubkit.com)
- [Getting Started](https://docs.stubkit.com/getting-started)
- [API Reference](https://docs.stubkit.com/api-reference)
- [Dashboard](https://app.stubkit.com)

## License

MIT — Cryptosam LLC
