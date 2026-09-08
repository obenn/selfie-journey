#!/bin/bash
set -euo pipefail

# Create a numbered archive for internal testing, retaining external eligibility.
# Upload from Xcode Organizer using App Store Connect, then choose tester groups.
release_build="${1:?Usage: scripts/archive-testflight.sh BUILD_NUMBER [VERSION]}"
release_version="${2:-1.0}"
if [[ ! "$release_build" =~ ^[1-9][0-9]*$ ]] || [[ ! "$release_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Use a positive build number and a version such as 1.0." >&2
    exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
archive_path="$repo_dir/build/releases/SelfieJourney-$release_version-$release_build.xcarchive"
if [[ -e "$archive_path" ]]; then
    echo "Archive already exists: $archive_path. Choose a new build number." >&2
    exit 1
fi
mkdir -p "$repo_dir/build/releases"

xcodebuild -project "$repo_dir/SelfieJourney.xcodeproj" -scheme SelfieJourney \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath "$repo_dir/build/DerivedData-Release" \
    -archivePath "$archive_path" -allowProvisioningUpdates \
    CURRENT_PROJECT_VERSION="$release_build" MARKETING_VERSION="$release_version" \
    LD=/usr/bin/clang LDPLUSPLUS=/usr/bin/clang++ archive

echo "Archive ready: $archive_path"
echo "Open it in Xcode Organizer, choose Distribute App > App Store Connect."
echo "Assign only the Internal group now. Add the same build to External when you choose."
