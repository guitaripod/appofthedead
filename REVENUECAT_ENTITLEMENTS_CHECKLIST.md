# RevenueCat Entitlements Configuration Checklist

## IMPORTANT: Without these entitlements configured, purchases will complete but paths won't unlock!

Go to RevenueCat Dashboard > Entitlements and create ALL of these:

### Path Entitlements (21 total)
Each entitlement ID must match exactly!

- [ ] `path_christianity` → Link to product: `com.appofthedead.path.christianity`
- [ ] `path_islam` → Link to product: `com.appofthedead.path.islam`
- [ ] `path_buddhism` → Link to product: `com.appofthedead.path.buddhism`
- [ ] `path_hinduism` → Link to product: `com.appofthedead.path.hinduism`
- [ ] `path_ancient_egyptian` → Link to product: `com.appofthedead.path.egyptian`
- [ ] `path_greek` → Link to product: `com.appofthedead.path.greek`
- [ ] `path_norse` → Link to product: `com.appofthedead.path.norse`
- [ ] `path_shinto` → Link to product: `com.appofthedead.path.shinto`
- [ ] `path_zoroastrian` → Link to product: `com.appofthedead.path.zoroastrian`
- [ ] `path_sikhism` → Link to product: `com.appofthedead.path.sikhism`
- [ ] `path_aztec_mictlan` → Link to product: `com.appofthedead.path.aztecmictlan`
- [ ] `path_taoism` → Link to product: `com.appofthedead.path.taoism`
- [ ] `path_mandaeism` → Link to product: `com.appofthedead.path.mandaeism`
- [ ] `path_wicca` → Link to product: `com.appofthedead.path.wicca`
- [ ] `path_bahai` → Link to product: `com.appofthedead.path.bahai`
- [ ] `path_tenrikyo` → Link to product: `com.appofthedead.path.tenrikyo`
- [ ] `path_aboriginal_dreamtime` → Link to product: `com.appofthedead.path.aboriginaldreamtime`
- [ ] `path_native_american` → Link to product: `com.appofthedead.path.nativeamerican`
- [ ] `path_anthroposophy` → Link to product: `com.appofthedead.path.anthroposophy`
- [ ] `path_theosophy` → Link to product: `com.appofthedead.path.theosophy`
- [ ] `path_swedenborgian` → Link to product: `com.appofthedead.path.swedenborgian`

### Other Entitlements

- [ ] `oracle_unlimited` → Link to: `com.appofthedead.oracle.wisdom`
- [ ] `ultimate` → Link to: `com.appofthedead.ultimate` AND ALL 21 path products
- [ ] `deity_egyptian` → Link to: `com.appofthedead.deities.egyptian`
- [ ] `deity_greek` → Link to: `com.appofthedead.deities.greek`
- [ ] `deity_eastern` → Link to: `com.appofthedead.deities.eastern`
- [ ] `xp_boost` → Link to: `com.appofthedead.boost.xp7`
- [ ] `cloud_sync` → Link to: `com.appofthedead.ultimate` (only)

## How to Create Each Entitlement:

1. Go to RevenueCat Dashboard > Entitlements
2. Click "New"
3. Enter the **exact** identifier from the list above
4. Add description (e.g., "Christianity Path Access")
5. Click "Add Products"
6. Select the corresponding product(s)
7. Save

## Testing After Configuration:

1. Make a test purchase
2. Check the debug log for `"entitlements":{...}` - it should now show the granted entitlement
3. The path should unlock immediately after purchase

## Note on Entitlement IDs:

The entitlement IDs use underscores (e.g., `path_ancient_egyptian`) while the belief system IDs in aotd.json use hyphens (e.g., `egyptian-afterlife`). The StoreManager code handles this conversion.