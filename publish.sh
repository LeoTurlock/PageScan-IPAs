#!/bin/zsh
# Publishes a PageScan build to this Feather source:
#   1. builds an unsigned IPA from ~/Documents/Code/PageScan (unless one is given; Feather signs it on the phone)
#   2. uploads it as a GitHub release asset (IPAs don't belong in git)
#   3. adds it as the newest entry in apps.json, then commits and pushes
#
# usage: publish.sh "<notes shown in Feather>" [file.ipa]
set -euo pipefail
cd "$(dirname "$0")"

[ $# -ge 1 ] || { sed -n 2,7p "$0"; exit 1; }
NOTES=$1
IPA=${2:-}
PROJECT=${PAGESCAN_PROJECT:-$HOME/Documents/Code/PageScan}
# Build products go on the external SSD when it's there: the Mac's own disk is nearly full.
SCRATCH=${PAGESCAN_BUILD:-"/Volumes/SSD 980 1TB/PageScanDB/build"}
[[ -d "${SCRATCH:h}" ]] || SCRATCH=$(mktemp -d /tmp/pagescan-build.XXXX)
REPO=LeoTurlock/PageScan-IPAs
WORK=$(mktemp -d /tmp/pagescan-publish.XXXX)
trap 'rm -rf "$WORK"' EXIT

if [[ -z "$IPA" ]]; then
  echo "▸ Building unsigned Release…"
  xcodebuild -project "$PROJECT/PageScan.xcodeproj" -target PageScan -configuration Release -sdk iphoneos \
    SYMROOT="$SCRATCH/sym" OBJROOT="$SCRATCH/obj" CODE_SIGNING_ALLOWED=NO -quiet build
  mkdir -p "$WORK/Payload"
  cp -R "$SCRATCH/sym/Release-iphoneos/PageScan.app" "$WORK/Payload/"
  (cd "$WORK" && zip -qry PageScan.ipa Payload)
  IPA="$WORK/PageScan.ipa"
fi
[ -f "$IPA" ] || { echo "no such file: $IPA"; exit 1; }

unzip -q -o "$IPA" 'Payload/*.app/Info.plist' -d "$WORK/info"
PLIST=$(find "$WORK/info/Payload" -maxdepth 2 -name Info.plist | head -1)
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST")
STAMP=$(date +%Y%m%d.%H%M)
TAG="v$VERSION-$STAMP"
ASSET="PageScan-$VERSION-$STAMP.ipa"
cp "$IPA" "$WORK/$ASSET"

git pull -q --ff-only 2>/dev/null || true
gh release create "$TAG" "$WORK/$ASSET" --repo "$REPO" --title "PageScan $VERSION ($STAMP)" --notes "$NOTES"

/usr/bin/python3 -I tools/add_version.py apps.json \
    --name "PageScan" \
    --bundle-id "$BUNDLE_ID" \
    --version "$VERSION" \
    --full-date "$(date +%Y%m%d%H%M%S)" \
    --size "$(stat -f %z "$IPA")" \
    --url "https://github.com/$REPO/releases/download/$TAG/$ASSET" \
    --notes "$NOTES"

git add apps.json
git commit -q -m "Add PageScan $VERSION ($TAG)"
git push -q
echo "✓ Published $ASSET ($TAG, build $BUILD)"
