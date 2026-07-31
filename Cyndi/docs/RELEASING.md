# Releasing Cyndi

Six steps. Run them in order, from `Cyndi/`.

Replace `X.Y.Z` with the new version — no `v` prefix here, the scripts add it.

```sh
cd Cyndi

# 1. main must be clean and current, or you ship the wrong code
git checkout main && git pull --ff-only && git status --short

# 2. tag
git tag vX.Y.Z && git push origin vX.Y.Z

# 3. build + sign  (spctl says "rejected" here — that's expected, not yet notarized)
make app VERSION=X.Y.Z

# 4. notarize  (uploads to Apple, waits, staples the ticket — takes a few minutes)
make notarize

# 5. dmg + GitHub release  (refuses to run unless step 4 stapled a ticket)
make dmg VERSION=X.Y.Z

# 6. bump the tap — NOTHING REACHES USERS UNTIL THIS IS PUSHED
```

Step 6, using the `sha256` that step 5 printed:

```sh
TAP="$(brew --repository)/Library/Taps/marufahmed-afk/homebrew-cyndi"
# edit Casks/cyndi.rb in $TAP: set version "X.Y.Z" and the new sha256
git -C "$TAP" commit -am "chore: bump cyndi cask to X.Y.Z"
git -C "$TAP" push
```

Verify:

```sh
brew update && brew info --cask cyndi   # must print X.Y.Z
```

## The three things that bite

**1. The tap is a separate repo.** The release on GitHub is not the release users
get. `brew upgrade --cask cyndi` reads
[`marufahmed-afk/homebrew-cyndi`](https://github.com/marufahmed-afk/homebrew-cyndi).
Skip step 6 and the version is published but nobody can install it — this is
exactly how `0.2.2` sat unavailable.

**2. `Cyndi/homebrew-tap/Casks/cyndi.rb` is a decoy.** A stale copy in this repo
that Homebrew never reads. It drifted to `0.2.1` while users were on `0.2.2`.
Only `$TAP` above matters. Delete the copy when someone has a spare minute.

**3. The tap remote is HTTPS with no saved credentials,** so `git push` there
fails with `could not read Username for 'https://github.com'`. One-shot
workaround:

```sh
git -C "$TAP" -c credential.helper='!f() { test "$1" = get && echo "password=$(gh auth token)" && echo "username=x-access-token"; }; f' push origin main
```

Permanent fix — switch it to SSH, matching the main repo:

```sh
git -C "$TAP" remote set-url origin git@github.com:marufahmed-afk/homebrew-cyndi.git
```

## Version numbers

Patch for fixes, minor for features. Check what's already taken —
`git tag --sort=-v:refname | head -3` — because a tag can exist for a version
that never shipped to the tap.

## If notarization fails

`make notarize` needs a stored credential named `cyndi-notary`. If it's missing:

```sh
xcrun notarytool store-credentials cyndi-notary \
  --key /path/to/AuthKey_XXXX.p8 --key-id KEYID --issuer ISSUER-UUID
```

To check a rejection:

```sh
xcrun notarytool history --keychain-profile cyndi-notary
xcrun notarytool log <submission-id> --keychain-profile cyndi-notary
```

## Release notes

`make dmg` creates the release with a one-line placeholder. Replace it with what
actually changed:

```sh
gh release edit vX.Y.Z --notes "$(cat <<'EOF'
## Fixed
- Thing that was broken (#PR)
EOF
)"
```

## Checks worth doing

Confirm the fix is really in the signed binary before notarizing:

```sh
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" dist/Cyndi.app/Contents/Info.plist
strings dist/Cyndi.app/Contents/MacOS/Cyndi | grep <a-string-from-your-change>
```

Confirm the notarized bundle passes Gatekeeper:

```sh
xcrun stapler validate dist/Cyndi.app
spctl -a -vv dist/Cyndi.app     # want: accepted / Notarized Developer ID
```

Confirm the published DMG matches the cask sha256:

```sh
shasum -a 256 dist/Cyndi.dmg
```

## Note: the tap repo is private

`brew install --cask marufahmed-afk/cyndi/cyndi` — the command in the README —
works for you because your local clone is authenticated. It fails at `brew tap`
for everyone else. Make the tap public if the app is meant to be publicly
installable.
