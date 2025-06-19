# RevenueCat Setup Instructions

Follow these steps to configure RevenueCat for App of the Dead:

## 1. Create RevenueCat Account
1. Go to https://app.revenuecat.com/signup
2. Create a new account or sign in

## 2. Create New Project
1. Click "Create New Project"
2. Name: "App of the Dead"
3. Platform: iOS
4. Bundle ID: `com.marcusziade.aotd` (matches Info.plist)

## 3. Configure Products

### Create Products in App Store Connect First
Go to App Store Connect > Your App > In-App Purchases and create ALL of these products:

#### Individual Paths ($2.99 each) - Complete List
1. `com.appofthedead.path.christianity` - Christianity Path ✓
2. `com.appofthedead.path.islam` - Islam Path ✓
3. `com.appofthedead.path.buddhism` - Buddhism Path ✓
4. `com.appofthedead.path.hinduism` - Hinduism Path ✓
5. `com.appofthedead.path.egyptian` - Ancient Egyptian Path ✓
6. `com.appofthedead.path.greek` - Greek Path ✓
7. `com.appofthedead.path.norse` - Norse Path ✓
8. `com.appofthedead.path.shinto` - Shinto Path ✓
9. `com.appofthedead.path.zoroastrian` - Zoroastrian Path ✓
10. `com.appofthedead.path.sikhism` - Sikhism Path ✓
11. `com.appofthedead.path.aztecmictlan` - Aztec Mictlan Path ✓
12. `com.appofthedead.path.taoism` - Taoism Path ✓
13. `com.appofthedead.path.mandaeism` - Mandaeism Path ✓
14. `com.appofthedead.path.wicca` - Wicca Path ✓
15. `com.appofthedead.path.bahai` - Baha'i Path ✓
16. `com.appofthedead.path.tenrikyo` - Tenrikyo Path ✓
17. `com.appofthedead.path.aboriginaldreamtime` - Aboriginal Dreamtime Path ✓
18. `com.appofthedead.path.nativeamerican` - Native American Visions Path ✓
19. `com.appofthedead.path.anthroposophy` - Anthroposophy Path ✓
20. `com.appofthedead.path.theosophy` - Theosophy Path ✓
21. `com.appofthedead.path.swedenborgian` - Swedenborgian Visions Path ✓

**Note:** The duplicate paths (egyptianafterlife and greekunderworld) have been removed as they map to the same content as ancient_egyptian and greek

#### Oracle Access ($9.99)
- `com.appofthedead.oracle.wisdom` - Oracle Wisdom Pack ✓

#### Ultimate Pack ($19.99)
- `com.appofthedead.ultimate` - Ultimate Enlightenment ✓

#### Deity Packs ($1.99 each)
- `com.appofthedead.deities.egyptian` - Egyptian Pantheon ✓
- `com.appofthedead.deities.greek` - Greek Guides ✓
- `com.appofthedead.deities.eastern` - Eastern Wisdom ✓

#### Boosts ($0.99)
- `com.appofthedead.boost.xp7` - 7-Day XP Boost ✓

## 4. Add Products to RevenueCat
1. Go to Products in RevenueCat
2. Click "New" for each product
3. Enter the Product ID exactly as above
4. Select product type (Non-Consumable for all except XP Boost which is Consumable)

## 5. Create Entitlements
Go to Entitlements and create entitlements for ALL products:

**For Implemented Paths (1-9):**
1. **path_christianity** - Links to christianity product
2. **path_islam** - Links to islam product
3. **path_buddhism** - Links to buddhism product
4. **path_hinduism** - Links to hinduism product
5. **path_ancient_egyptian** - Links to egyptian product
6. **path_greek** - Links to greek product
7. **path_norse** - Links to norse product
8. **path_shinto** - Links to shinto product
9. **path_zoroastrian** - Links to zoroastrian product

**For Additional Paths (10-21):**
10. **path_sikhism** - Links to sikhism product
11. **path_aztec_mictlan** - Links to aztecmictlan product
12. **path_taoism** - Links to taoism product
13. **path_mandaeism** - Links to mandaeism product
14. **path_wicca** - Links to wicca product
15. **path_bahai** - Links to bahai product
16. **path_tenrikyo** - Links to tenrikyo product
17. **path_aboriginal_dreamtime** - Links to aboriginaldreamtime product
18. **path_native_american** - Links to nativeamerican product
19. **path_anthroposophy** - Links to anthroposophy product
20. **path_theosophy** - Links to theosophy product
21. **path_swedenborgian** - Links to swedenborgian product

**Other Entitlements:**
22. **oracle_unlimited** - Links to oracle wisdom product
23. **ultimate** - Links to ultimate product AND ALL 21 path products
24. **deity_egyptian** - Links to egyptian pantheon product
25. **deity_greek** - Links to greek guides product
26. **deity_eastern** - Links to eastern wisdom product
27. **xp_boost** - Links to xp boost product
28. **cloud_sync** - Links to ultimate product only

## 6. Create Offerings

Go to RevenueCat Dashboard > Offerings and create the following structure:

### Create Default Offering
1. Click "New Offering"
2. Identifier: `default`
3. Description: "Main offering for App of the Dead"
4. Make it current by toggling "Current Offering" ON

### Add Packages to Default Offering

RevenueCat uses predefined package identifiers. Here's exactly how to set them up:

#### Package 1: Ultimate Package ($rc_annual)
- Click "Add Package" 
- Identifier: Select `$rc_annual` from dropdown (even though it's not annual, this is for your primary/featured product)
- Products: Add `com.appofthedead.ultimate`
- This will be marked as "Recommended" automatically

#### Package 2: Oracle Package ($rc_monthly)
- Click "Add Package"
- Identifier: Select `$rc_monthly` from dropdown (again, not monthly, but secondary featured product)
- Products: Add `com.appofthedead.oracle.wisdom`

#### Package 3: Egyptian Pantheon
- Click "Add Package"
- Identifier: Select `Custom` and enter: `deity_egyptian`
- Products: Add `com.appofthedead.deities.egyptian`

#### Package 4: Greek Guides
- Click "Add Package"
- Identifier: Select `Custom` and enter: `deity_greek`
- Products: Add `com.appofthedead.deities.greek`

#### Package 5: Eastern Wisdom
- Click "Add Package"
- Identifier: Select `Custom` and enter: `deity_eastern`
- Products: Add `com.appofthedead.deities.eastern`

#### Package 6: XP Boost ($rc_weekly)
- Click "Add Package"
- Identifier: Select `$rc_weekly` from dropdown
- Products: Add `com.appofthedead.boost.xp7`

### Important: How to Handle Individual Paths

Individual paths should NOT all be in one package. Instead:

1. **Option A - Recommended**: Don't put paths in packages at all
   - Query products directly by their ProductIdentifier when showing the paywall
   - This gives you the most flexibility to show/hide specific paths

2. **Option B - If you must use packages**: Create a custom package for EACH path
   - Package identifier: `path_christianity` → Product: `com.appofthedead.path.christianity`
   - Package identifier: `path_islam` → Product: `com.appofthedead.path.islam`
   - (Repeat for all 21 paths)
   - This is tedious but allows package-based retrieval

### Final Offering Structure

Your default offering should look like:
```
Default Offering (current)
├── $rc_annual → Ultimate Enlightenment ($19.99) - RECOMMENDED
├── $rc_monthly → Oracle Wisdom Pack ($9.99)
├── deity_egyptian → Egyptian Pantheon ($1.99)
├── deity_greek → Greek Guides ($1.99)
├── deity_eastern → Eastern Wisdom ($1.99)
└── $rc_weekly → 7-Day XP Boost ($0.99)
```

Individual paths (21 products) are handled separately, not in packages.

## 7. Get API Keys
1. Go to Project Settings > API Keys
2. Copy the **Public SDK Key** (starts with `appl_`)
3. ✅ **Already configured in `StoreManager.swift`**: `appl_EPdbsDpeVyslVzSVIWLwbgIGKsc`

## 8. Configure App

### Add RevenueCat SDK
1. ✅ **SDK Already Installed** via `https://github.com/RevenueCat/purchases-ios-spm.git`
2. ✅ **StoreManager.swift** fully implemented with RevenueCat integration
3. ✅ **AppDelegate.swift** already calls `StoreManager.shared.configure()` at launch

### ✅ StoreManager.swift Implementation Complete

The `StoreManager.swift` now includes:
- Full RevenueCat SDK integration
- User authentication (login/logout)
- Product fetching for paths, deity packs, and featured offerings
- Purchase handling with proper error management
- Entitlement checking for all product types
- Automatic price localization
- PurchasesDelegate implementation for real-time updates
- Notification posting for purchase events

## 9. Testing
1. Create Sandbox Test Account in App Store Connect
2. Sign out of real Apple ID on test device
3. Run app and test purchases with sandbox account
4. Check RevenueCat dashboard for test transactions

## 10. Important Settings
In RevenueCat Project Settings:
- Enable "Transfer Purchases" for users switching devices
- Set "Restore Behavior" to "Transfer if there are no active subscriptions"
- Enable "iOS App Tracking Transparency" if you plan to use attribution

## Product Structure Summary

### Free Tier
- Judaism path (always free - no product needed)
- 3 Oracle consultations per deity
- Basic achievements
- Local progress only

### Complete Product List Summary
- **Individual Paths**: 21 × $2.99 = $62.79
- **Oracle Wisdom**: 1 × $9.99 = $9.99
- **Ultimate Pack**: 1 × $19.99 = $19.99 (includes all paths + oracle + cloud sync)
- **Deity Packs**: 3 × $1.99 = $5.97
- **XP Boost**: 1 × $0.99 = $0.99

**Total Products: 27**
**Total Potential Revenue (if all purchased separately): $99.73**

## Implementation Status

### ✅ FULLY IMPLEMENTED
- **Product.swift now includes**: All 21 paid paths + 6 other products = 27 total products
- **aotd.json contains**: 22 belief systems (21 paid + Judaism free)
- **ID mappings**: Fixed to match aotd.json exactly

## Next Steps

1. Create all 27 products in App Store Connect using the exact Product IDs listed above
2. Configure all products in RevenueCat
3. Add RevenueCat SDK to the Xcode project
4. ✅ StoreManager.swift already updated with RevenueCat API key
5. Test all purchase flows in sandbox environment

## Notes
- All products are non-consumable except XP Boost (consumable)
- Ultimate pack must include ALL paths, not just the 9 currently implemented
- Cloud sync is exclusive to Ultimate pack
- Ensure product IDs match EXACTLY between App Store Connect, RevenueCat, and your code
- Free tier (Judaism) does NOT need a product - it's handled in code

## Handling Individual Path Products in Code

Since you have 21 individual path products and they're not in packages, here's how to handle them:

```swift
// In your PaywallViewController or wherever you show paths
func loadPathProduct(for beliefSystem: BeliefSystem, completion: @escaping (StoreProduct?, String?) -> Void) {
    // Skip Judaism - it's free
    if beliefSystem.id == "judaism" {
        completion(nil, nil)
        return
    }
    
    // Find the matching ProductIdentifier
    guard let productId = ProductIdentifier.allCases.first(where: { $0.beliefSystemId == beliefSystem.id }) else {
        completion(nil, nil)
        return
    }
    
    // Fetch the product directly
    Purchases.shared.getProducts([productId.rawValue]) { products in
        if let product = products.first {
            completion(product, product.localizedPriceString)
        } else {
            completion(nil, "$2.99") // Fallback price
        }
    }
}

// Check if user has access to a path
func hasPathAccess(beliefSystemId: String) -> Bool {
    // Judaism is always free
    if beliefSystemId == "judaism" { return true }
    
    // Check entitlements
    if let customerInfo = Purchases.shared.cachedCustomerInfo {
        // Check ultimate access first
        if customerInfo.entitlements["ultimate"]?.isActive == true {
            return true
        }
        
        // Check specific path entitlement
        let pathEntitlement = "path_\(beliefSystemId.replacingOccurrences(of: "-", with: "_"))"
        return customerInfo.entitlements[pathEntitlement]?.isActive == true
    }
    
    return false
}
```

This approach gives you maximum flexibility to display paths in your UI without creating 21 packages in RevenueCat.