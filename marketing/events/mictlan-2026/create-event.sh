#!/usr/bin/env bash
#
# Creates the "Journey to Mictlan" Dia de los Muertos in-app event in App
# Store Connect: the event, all 10 locale localizations, and the two event
# images (EVENT_CARD + EVENT_DETAILS_PAGE) uploaded per locale.
#
# NOT RUN YET. Read marketing/events/mictlan-2026/README.md first: it
# verifies every flag below against `asc app-events ... --help` and the
# current App Store Connect in-app event rules. This script only creates
# and populates the event in DRAFT/READY_FOR_REVIEW state - it deliberately
# stops short of `asc app-events submit`, which is a separate, explicit
# human step once the event has been eyeballed in the App Store Connect UI.
#
# Requires: asc (authenticated), jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASC="${ASC_BIN:-asc}"
COPY_JSON="${SCRIPT_DIR}/copy.json"
CARD_PNG="${SCRIPT_DIR}/card.png"
DETAIL_PNG="${SCRIPT_DIR}/detail.png"

APP_ID="6746733380"

for f in "$COPY_JSON" "$CARD_PNG" "$DETAIL_PNG"; do
  [ -f "$f" ] || { echo "Missing required file: $f" >&2; exit 1; }
done
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v "$ASC" >/dev/null || { echo "asc CLI not found (set ASC_BIN)" >&2; exit 1; }

NAME="$(jq -r '.referenceName' "$COPY_JSON")"
EVENT_TYPE="$(jq -r '.eventType' "$COPY_JSON")"
PRIORITY="$(jq -r '.priority' "$COPY_JSON")"
PURPOSE="$(jq -r '.purpose' "$COPY_JSON")"
PURCHASE_REQ="$(jq -r '.purchaseRequirement' "$COPY_JSON")"
PRIMARY_LOCALE="$(jq -r '.primaryLocale' "$COPY_JSON")"
DEEP_LINK="$(jq -r '.deepLink' "$COPY_JSON")"
EVENT_START="$(jq -r '.eventStart' "$COPY_JSON")"
EVENT_END="$(jq -r '.eventEnd' "$COPY_JSON")"
PUBLISH_START="$(jq -r '.publishStart' "$COPY_JSON")"
TERRITORIES="$("$ASC" pricing territories list --paginate --output json | jq -r '[.data[].id] | join(",")')"

echo "== Creating in-app event: ${NAME} =="
CREATE_OUT="$("$ASC" app-events create \
  --app "$APP_ID" \
  --name "$NAME" \
  --event-type "$EVENT_TYPE" \
  --priority "$PRIORITY" \
  --purpose "$PURPOSE" \
  --purchase-requirement "$PURCHASE_REQ" \
  --primary-locale "$PRIMARY_LOCALE" \
  --deep-link "$DEEP_LINK" \
  --start "$EVENT_START" \
  --end "$EVENT_END" \
  --publish-start "$PUBLISH_START" \
  --territories "$TERRITORIES" \
  --output json)"

echo "$CREATE_OUT" | jq .

# Verify this against the actual `create` response the first time this
# script is run for real - .data.id matches the shape `asc app-events list`
# returns (each event is {data: {id, type, attributes}}), but this was
# never exercised against a real `create` call (read-only constraint while
# building this kit).
EVENT_ID="$(echo "$CREATE_OUT" | jq -r '.data.id // .id')"
if [ -z "$EVENT_ID" ] || [ "$EVENT_ID" = "null" ]; then
  echo "Could not extract event id from create response - inspect the JSON above and fix the jq filter." >&2
  exit 1
fi
echo "Event ID: ${EVENT_ID}"

echo "== Creating localizations =="
for LOCALE in $(jq -r '.localizations | keys[]' "$COPY_JSON"); do
  L_NAME="$(jq -r --arg l "$LOCALE" '.localizations[$l].name' "$COPY_JSON")"
  L_SHORT="$(jq -r --arg l "$LOCALE" '.localizations[$l].shortDescription' "$COPY_JSON")"
  L_LONG="$(jq -r --arg l "$LOCALE" '.localizations[$l].longDescription' "$COPY_JSON")"

  echo "-- ${LOCALE}: ${L_NAME}"
  LOC_OUT="$("$ASC" app-events localizations create \
    --event-id "$EVENT_ID" \
    --locale "$LOCALE" \
    --name "$L_NAME" \
    --short-description "$L_SHORT" \
    --long-description "$L_LONG" \
    --output json)"
  echo "$LOC_OUT" | jq .

  echo "   uploading card.png (EVENT_CARD)"
  "$ASC" app-events screenshots create \
    --event-id "$EVENT_ID" \
    --locale "$LOCALE" \
    --path "$CARD_PNG" \
    --asset-type EVENT_CARD \
    --output json | jq .

  echo "   uploading detail.png (EVENT_DETAILS_PAGE)"
  "$ASC" app-events screenshots create \
    --event-id "$EVENT_ID" \
    --locale "$LOCALE" \
    --path "$DETAIL_PNG" \
    --asset-type EVENT_DETAILS_PAGE \
    --output json | jq .
done

echo "== Done =="
echo "Event ${EVENT_ID} created with ${PRIMARY_LOCALE} as primary locale, $(jq -r '.localizations | keys | length' "$COPY_JSON") localizations, and card/detail images on every locale."
echo "Next (manual, not part of this script):"
echo "  1. Review the event in App Store Connect (Distribution > App Events)."
echo "  2. Confirm the event card/details preview and that no locale is missing an asset."
echo "  3. When ready: asc app-events submit --event-id \"${EVENT_ID}\" --app \"${APP_ID}\" --confirm"
