# Cyndi Homebrew tap

Source of truth for the `cyndi` cask. The live tap lives in a **separate repo**,
`marufahmed-afk/homebrew-cyndi`, because Homebrew requires the `homebrew-` name prefix.

## One-time: create the tap repo

```sh
gh repo create marufahmed-afk/homebrew-cyndi --public \
  --description "Homebrew tap for Cyndi"
git clone git@github.com:marufahmed-afk/homebrew-cyndi.git
mkdir -p homebrew-cyndi/Casks
cp Casks/cyndi.rb homebrew-cyndi/Casks/
( cd homebrew-cyndi && git add Casks/cyndi.rb && git commit -m "Add cyndi cask" && git push )
```

## Cut a release

From the `Cyndi/` directory, with a Developer ID cert in the keychain and a stored
notary profile (see `scripts/notarize.sh` for how to store one):

```sh
make app VERSION=0.1.0      # build + sign
make notarize               # notarize + staple
make release VERSION=0.1.0  # dmg + GitHub release; prints the sha256
```

Then update `Casks/cyndi.rb` in the tap repo with the printed `version` and `sha256`,
commit, and push.

## Install (users / your friend)

```sh
brew install --cask marufahmed-afk/cyndi/cyndi
```

`brew tap marufahmed-afk/cyndi` then `brew install --cask cyndi` also works.

## Upgrades

Bump `version` + `sha256` in the tap after each release. Users get it with
`brew upgrade --cask cyndi`.
