# Dia de los Muertos in-app event: "Journey to Mictlan"

App Store in-app event kit for the 2026 Aztec Mictlan path event. Nothing in
this directory has been sent to App Store Connect - `create-event.sh` is
written and verified against `asc --help` output but has not been run.

## Files

- `copy.json` - event metadata (dates, badge, deep link) plus the 10 locale
  localizations (name / short description / long description), all
  length-checked against Apple's limits.
- `card.png` - Event Card (Discovery view), 1920x1080, 16:9.
- `detail.png` - Event Details Page, 1080x1920, 9:16.
- `create-event.sh` - creates the event, all 10 localizations, and uploads
  both images to every locale. Stops before `asc app-events submit` (that's
  a deliberate separate step).

## Rules verified, and sources

Pulled from Apple's own in-app events documentation
([developer.apple.com/app-store/in-app-events](https://developer.apple.com/app-store/in-app-events/))
and the App Store Connect media-spec reference
([developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-media-and-audio-specifications](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-media-and-audio-specifications/)),
cross-checked against `asc app-events create --help`,
`asc app-events localizations create --help` and
`asc app-events screenshots create --help` on this machine.

**Character limits** (all counted with Python `len()`, i.e. Unicode code
points - every locale in `copy.json` was checked against these and fits):
- Name: 30 characters, title case. No calls-to-action ("Watch now"), no
  words that just restate the badge ("Special Event"), no ALL CAPS / excess
  punctuation.
- Short description: 50 characters, sentence case.
- Long description: 120 characters, sentence case. Describe the actual
  experience; no unverifiable superlatives ("the best," "#1"), no general
  app-promotion copy.

**Badge / event type**: `SPECIAL_EVENT` - "limited-time events not captured
by other badges," which fits a cultural-calendar event better than
`CHALLENGE`, `COMPETITION`, `LIVE_EVENT`, `PREMIERE`, `NEW_SEASON` or
`MAJOR_UPDATE` (all wrong shape for this).

**Image specs**:
- Event Card: 16:9, 1920x1080 min / 3840x2160 max, .jpg/.jpeg/.png, 500MB
  max. `card.png` is exactly 1920x1080.
- Event Details Page: 9:16, 1080x1920 min / 2160x3840 max, same formats/size
  cap. `detail.png` is exactly 1080x1920.
- Apple's own docs do **not** publish exact safe-area pixel margins for
  either asset (confirmed by reading the media-spec page directly - it
  covers only aspect ratio, resolution and audio, not a safe box). The
  closest documented guidance is App Store Connect's own live preview when
  uploading. In the absence of a published number, both images keep all
  essential content (the nine-level motif, the candle) within a centered
  ~80% safe zone and push only decorative, low-priority elements (drifting
  petals, corner flourishes) toward the edges, per the general "keep detail
  away from the extreme edges" practice documented by third-party
  agencies that build these assets regularly (e.g. AppLaunchFlow's 2026
  guide). Verify visually in ASC's own preview before submitting.
- Apple recommends avoiding text or logos in event media, especially the
  event or app name (they're redundant with the metadata fields the
  platform already renders on top). Both images are entirely text-free.

**Pricing / cost language**: Apple's docs are explicit - "do not include
specific prices in metadata" (rejection risk), because prices vary by
region and change independently of the event; use the purchase-requirement
field instead. That field only supports `NO_COST_ASSOCIATED` today (per
`asc app-events create --help`), which is what `copy.json` sets.

We went further than "no specific prices" and avoided the word "free"
entirely. Two reasons: (1) it isn't precisely true - the mechanic isn't a
price drop, it's a time-boxed unlock that becomes permanent only if you
start a lesson inside the window, so "free" undersells/misdescribes the
actual rule; (2) Marcus's house rule against fake urgency and hype language
argues for the literal mechanic over a marketing shorthand. The copy says
the path is "open to everyone" / "for everyone" through the window, and
that starting a lesson in that window means "it's yours to keep" - accurate
to both the game mechanic and the no-pricing-language rule, without
borrowing "free"'s promotional connotation.

**Scheduling**: events can run up to 31 days and can be promoted starting
**up to 14 days before** the event start. `publishStart` (2026-10-10) is
set to exactly 14 days before `eventStart` (2026-10-24) - the maximum lead
time, since this event benefits from advance discovery. `eventEnd` is
2026-11-02T23:59:59Z, matching "end of day" on Nov 2.

Note: the *event's* start/end in App Store Connect is one global instant
(events can be customized per territory, but we're not scoping this one to
specific territories); the *app's* actual unlock logic reads device-local
Oct 24 - Nov 2, per the main branch's implementation. That means up to ~24h
of skew is possible at the edges between "the App Store says the event is
live" and "a given device's local clock says it's live" - expected, not a
bug, and not something this kit can or should paper over.

**Other constraints noted but not relevant here**: max 15 approved events
and 10 published events per app at once (this app currently has 0, per a
live `asc app-events list --app 6746733380` read), events are submitted
independent of app version, and deep links must be universal-link-style
(not shortened) - `appofthedead://path/aztec-mictlan` is a custom scheme
rather than a universal link; that's what the rest of the app already uses
for deep linking, so it's consistent with the existing scheme even though
Apple's own preference is universal links.

## Copy decisions

- **"Mictlan" is spelled to match the app's own shipped UI in every
  locale**, not left as plain Latin-script "Mictlan" everywhere. Checking
  `aotd/Resources/Localizable.xcstrings`'s `"Aztec Mictlan Path"` key (the
  actual path name a user sees on the home screen) shows the app already
  localizes the name itself: de/es/fr/it/pt-BR render it accented as
  "Mictlán", and ja/ko/zh-Hans/zh-Hant transliterate it outright (ja
  "ミクトラン", ko "믹틀란", zh-Hans "米克特兰", zh-Hant "米克特蘭"). The
  event copy now matches those exact spellings per locale (en-US keeps the
  unaccented "Mictlan," matching the app's English source string). Lesson
  and Oracle *content* is still English-only, which is orthogonal to this -
  the path *name* is what a user compares the event to, and it's already
  localized in-app, so the event copy needs to match it, not the body text.
- **"Aztec" in Korean is "아스텍," not "아스테카"** - the first draft used
  "아스테카" (closer to the Spanish/English "azteca"/"Aztec") in the short
  description, but the app's own shipped Korean string ("아스텍 믹틀란의
  길") uses "아스텍." Fixed to match.
- **Portuguese "afterlife" is "além," not "além-vida"** - the first draft's
  short description used the invented compound "além-vida"; the app's own
  pt-BR string for "Afterlife" ("Mestre do além") uses the plain, standard
  "além." Fixed to match.
- **No mention of the Mictlantecuhtli Oracle persona or its 3 free
  consultations** in the event metadata. It's true and relevant, but adding
  it would either blow the 120-character long-description limit in most
  locales or dilute the one concrete offer (the path unlock) the event
  actually names. It's a good candidate for a future, separate event or for
  What's New copy instead.
- **"Nine levels"** is stated as fact (it's in `aztec-mictlan.json` - nine
  named levels from Itzcuintlan to Chicunamictlan) but the **"four-year
  journey"** detail from the lore is deliberately left out of the event
  copy: the event window itself is 10 days, and pairing "four-year journey"
  with an actual 10-day promotion invites readers to conflate the in-game
  narrative timeframe with the real-world event duration.
- `purpose`: `APPROPRIATE_FOR_ALL_USERS`. This is a cultural-calendar event
  open to every user equally (new, lapsed or active), not an acquisition or
  win-back mechanic specifically - `ATTRACT_NEW_USERS` or
  `BRING_BACK_LAPSED_USERS` would overclaim the intent.
- `priority`: `HIGH`. Apple doesn't document precisely what this changes;
  treated it as "this is the app's real flagship seasonal event," matching
  the examples in `asc app-events create --help` that pair `HIGH` with a
  live/premiere-caliber event.

## Artwork

Procedurally generated with Pillow/numpy (script not included in this
directory - it's throwaway scratch code, not app or marketing source of
truth beyond the two PNGs it produced). Design:

- Nine nested, notch-cornered frames (`aztec-mictlan`'s nine named levels of
  Mictlan), warm maroon at the rim cooling through the path's own theme
  color (`#800020`, read directly from
  `aotd/Resources/belief_systems/aztec-mictlan.json`) into near-black at the
  center, where a single small warm ember/candle glow sits - the offering
  light at the end of the four-year journey, not a void.
- Marigold (cempasúchil) petals, procedurally drawn (five/six-petal
  clusters with a dark umber center), drifting mostly near the bright rim
  and thinning toward the dark center.
- Thin gold and bone-white step-fret (greca escalonada) corner flourishes -
  a generic, traditional Mesoamerican geometric motif, not any specific
  copyrighted artwork - nodding to the app's Papyrus gold-on-dark design
  system without literally reusing app UI.
- No text, no emoji, no skull iconography, no depiction of Mictlantecuhtli
  or any specific deity.

Iterated three times: v1 had a one-point-perspective bug (the "ceiling" and
"floor" bands of each stepped level converged into a bowtie/hourglass shape
instead of a tunnel) and sparkle-like petals; v2 fixed the geometry with
properly nested frames but the fill was flat, uniformly saturated orange
(more "sunset wallpaper" than "deep-night underworld") with petals clumped
into sticker-like bouquets; v3 (final) rebuilt the ring colors around the
path's actual maroon and pulled the petal clusters and large elements back
from the frame edges for safe-area margin.

## What was not done, and why

- **Nothing was created, submitted or changed in App Store Connect.** Per
  scope, all `asc` calls made while building this kit were read-only
  (`--help`, `search`, and one `app-events list --app 6746733380`, which
  confirmed the app currently has 0 in-app events and the live JSON:API
  response shape used to write `create-event.sh`'s `jq` extraction).
- **`create-event.sh`'s event-id extraction (`.data.id`) is inferred, not
  observed.** `asc app-events list` confirms the `{data: [...]}` envelope
  shape for *listing* events, but no `create` call was made (that would
  mutate ASC), so the exact shape of a single-resource `create` response
  was never seen directly. Check the first real run's JSON output against
  the `jq -r '.data.id // .id'` filter before trusting it unattended.
- **Per-locale artwork variants were not made.** The images are art-only
  (no text), so the same `card.png` / `detail.png` are uploaded to all 10
  locales; App Store Connect does technically allow distinct media per
  localization if that's ever wanted later.
- **The event was not submitted for review** (`asc app-events submit`) -
  intentionally left as a manual last step in `create-event.sh`'s closing
  output, after a human confirms the event in the App Store Connect UI.
