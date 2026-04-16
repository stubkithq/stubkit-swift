# Stubkit Swift SDK

Subscription validation for iOS, macOS, tvOS, watchOS, and visionOS.

## Install

Add to your Xcode project via Swift Package Manager:

```
https://github.com/stubkithq/stubkit-swift
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/stubkithq/stubkit-swift", from: "1.0.1")
```

## Quick Start

The SDK takes two auth inputs: a **publishable key** (safe to ship in the app)
for offering + event calls, and a **tenant JWT** callback that returns your
end-user's identity token for entitlement + purchase calls.

```swift
import Stubkit

// 1. Configure (once, at app launch)
Stubkit.configure(
    publishableKey: "pk_live_xxxxxxxxxxxxxxxxxxxxxxxx",
    appId: "your-app-id",
    getAuthToken: {
        // Return your tenant JWT — Supabase access token / Clerk JWT /
        // Firebase ID token / your custom RS256 token.
        try await authProvider.currentAccessToken()
    }
)

// 2. Check entitlement
let isPro = try await Stubkit.shared.isActive(userId: "user_123", entitlement: "pro")

// 3. Fetch paywall config
let offering = try await Stubkit.shared.getOffering()

// 4. Sync purchase (after StoreKit 2 transaction)
let entitlements = try await Stubkit.shared.syncPurchase(
    userId: "user_123",
    platform: .ios,
    productId: "com.myapp.pro",
    receipt: transaction.jwsRepresentation
)
```

## StoreKit 2 Integration

```swift
import StoreKit
import Stubkit

func handlePurchase(_ result: VerificationResult<Transaction>) async throws {
    guard case .verified(let transaction) = result else { return }

    _ = try await Stubkit.shared.syncPurchase(
        userId: currentUserId,
        platform: .ios,
        productId: transaction.productID,
        receipt: transaction.jwsRepresentation,
        transactionId: String(transaction.id)
    )

    await transaction.finish()
}
```

## Track behavioural events

Stubkit returns a paywall suggestion when an event-rule matches the user:

```swift
let result = try await Stubkit.shared.track(
    event: "hit_export_limit",
    properties: ["count": .int(5), "plan": .string("free")],
    userId: currentUserId
)
if let paywall = result.showPaywall {
    presentPaywall(paywall)
}
```

## API

### `Stubkit.configure(publishableKey:appId:getAuthToken:baseURL:)`
Initialize the SDK. Call once at app launch.

### `Stubkit.shared.isActive(userId:entitlement:) -> Bool`
Check if a user has an active entitlement. Uses tenant JWT.

### `Stubkit.shared.getEntitlements(userId:) -> [Entitlement]`
Get all entitlements for a user. Uses tenant JWT.

### `Stubkit.shared.syncPurchase(userId:platform:productId:receipt:transactionId:) -> [Entitlement]`
Submit a purchase receipt for validation. Uses tenant JWT.

### `Stubkit.shared.refresh(userId:) -> [Entitlement]`
Force refresh entitlements (bypass server cache). Uses tenant JWT.

### `Stubkit.shared.getOffering(slug:locale:) -> Offering`
Fetch paywall config. Uses publishable key.

### `Stubkit.shared.track(event:properties:userId:) -> TrackResult`
Record an event, receive an optional paywall suggestion back. Uses publishable key.

## Requirements

- iOS 15+ / macOS 12+ / tvOS 15+ / watchOS 8+ / visionOS 1+
- Swift 5.9+
- Xcode 15+

## Migrating from 1.0.0

`Stubkit.configure(apiKey:appId:)` is gone. Replace with
`Stubkit.configure(publishableKey:appId:getAuthToken:)`. Offering and track
calls now use the publishable key automatically; entitlement and purchase
calls use the JWT returned from your `getAuthToken` closure.

## Links

- [Documentation](https://docs.stubkit.com)
- [Getting Started](https://docs.stubkit.com/getting-started)
- [Tenant JWT setup](https://docs.stubkit.com/getting-started/tenant-jwt)
- [Dashboard](https://app.stubkit.com)

## License

MIT — Cryptosam LLC
