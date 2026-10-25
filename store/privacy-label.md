# App of the Dead App Privacy label

Answers for App Store Connect, App Privacy section. Apple does not expose this section through the API; `store/app-privacy.json` holds the same rows and is applied with `asc web privacy plan`, `apply` and `publish` (ops/runbooks/submissions-and-review.md). It matches `Resources/PrivacyInfo.xcprivacy` and the policy at https://midgarcorp.cc/legal/app-of-the-dead/privacy (source: `web/midgarcorp/src/content/legal/app-of-the-dead/privacy.html`, last updated 23 October 2026). The Privacy Policy URL on the app info (`store/metadata/ios/app-info/*.json`) and the policy link at the end of every description (`store/metadata/ios/version/*/*.json`) move to that address with this release; the old address `https://midgarcorp.cc/appofthedead/privacy` redirects to it. `midgar listing` pushes both and, under the `metadata_edit` policy, only with the founder at a terminal.

This replaces the earlier label, "Data Not Collected", which no longer holds once the app keeps a Midgar ID, asks the Midgar ledger what that ID owns and shows the Midgar portal.

## Top-level answers

- Do you or your third-party partners collect data from this app: Yes.
- Data used to track you: none. No data type is used for tracking. The app asks for no tracking permission and `NSPrivacyTracking` is false with no tracking domains.
- Privacy policy URL: https://midgarcorp.cc/legal/app-of-the-dead/privacy

## Data types collected

| Data type (Apple) | Linked to the user | Used to track | Purpose | What it is in App of the Dead |
| --- | --- | --- | --- | --- |
| Identifiers, User ID | Yes | No | App Functionality | The random Midgar ID: sent as the sign-in token to `api.midgarcorp.cc` to ask the purchase ledger what the ID owns and for "Your Midgar" in the More Apps screen. |
| Identifiers, Device ID | Yes | No | App Functionality | The app reads no advertising identifier and no vendor identifier. MidgarKit's App Attest key id, per app and per device, stored with the Midgar ID when the ID is created or joined. App Store and TestFlight builds use App Attest's production environment whether or not the app has the App Attest entitlement (Apple, App Attest Environment entitlement), so released builds create it. |
| Purchases, Purchase History | Yes | No | App Functionality | The App Store transactions of the paths, deity packs, Oracle Wisdom, Ultimate Enlightenment and the Premium subscription. The app buys them through StoreKit 2 with the Midgar ID as the App Store `appAccountToken` and reports each signed transaction to Midgar's purchase ledger, which verifies it from the signed App Store transaction and keeps it linked to the Midgar ID; the ledger also receives Apple's signed notifications for the app. |
| Usage Data, Product Interaction | No | No | Analytics | The anonymous More Apps events (opened, shown, tapped) sent by MidgarKit with no identifier. |

Everything else is "Data Not Collected".

## Data types answered "not collected", and why

- Contact Info, Contacts, User Content, Browsing History, Search History, Sensitive Info, Financial Info, Health & Fitness, Location: none. Oracle questions and answers are generated and kept on the device and never leave it.
- Diagnostics: the session log (`Library/Logs/aotd.log`) stays on the device. MetricKit is not collected.
- Other: the on-device model file is downloaded from Hugging Face, which receives an ordinary file request and the IP address; that is a download, not data the app collects, so it adds no data type.

## Third-party SDK notes

- The app links no purchase SDK: purchases run through StoreKit 2 and MidgarKit's `MidgarCommerce`, so no purchase data leaves the device except to Apple and to Midgar's ledger.
- MidgarKit: `MidgarPortal` ships a manifest that declares Product Interaction for Analytics, not linked, matching the row above.
- MLX, GRDB, swift-transformers and swift-huggingface: no data collected.
- Cloudflare: hosts the gateway and the services behind it and may keep standard request logs (IP address) for a limited time; IP address is not a data type in the label.

## Required-reason APIs (in the manifest, not in the label)

- Disk space `E174.1` (checks free space before the model download), File timestamp `C617.1`, UserDefaults `CA92.1` (own settings and caches).
