#!/usr/bin/env bash
#
# Cut a new release of this HACS integration.
#
#   ./release.sh <version>        e.g.  ./release.sh 1.1.0
#
# It bumps the version in custom_components/navien_water_heater/manifest.json,
# commits, pushes to main, and publishes a matching GitHub release (tag vX.Y.Z).
# HACS tracks *releases* for this repo, so publishing a release is the only thing
# that surfaces an update notification — pushing commits to main alone does not.
#
# Tip: edit CHANGES.md first if you want the change recorded in the changelog;
# this script will include it in the release commit.
#
set -euo pipefail

VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Usage: $0 <version>   e.g. $0 1.1.0" >&2; exit 1; }

cd "$(dirname "$0")"
MANIFEST="custom_components/navien_water_heater/manifest.json"
TAG="v${VERSION}"

[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || { echo "Switch to the main branch first." >&2; exit 1; }

# Bump only the version string; leave the rest of the manifest formatting intact.
python3 - "$MANIFEST" "$VERSION" <<'PY'
import re, sys
path, version = sys.argv[1], sys.argv[2]
text = open(path).read()
new, n = re.subn(r'("version"\s*:\s*")[^"]*(")', lambda m: m.group(1) + version + m.group(2), text, count=1)
if n != 1:
    sys.exit("error: could not find a version field in " + path)
open(path, "w").write(new)
PY

git add "$MANIFEST" CHANGES.md
git commit -m "Release ${TAG}"
git push

# --generate-notes auto-builds notes from commits since the last release.
gh release create "$TAG" --target main --title "$TAG" --generate-notes

echo "Published ${TAG} -> https://github.com/beastieb-b/navien/releases/tag/${TAG}"
