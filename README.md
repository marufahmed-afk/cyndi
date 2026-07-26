# cyndi

A tiny macOS app that lives at the notch. A row of **dots** hugs the notch — one per note — and **expands into sticky-notes / todos** when you click or hit a hotkey.

## Install

Requires macOS Sonoma (14) or newer, on a Mac with a notch. With [Homebrew](https://brew.sh):

```sh
brew install --cask marufahmed-afk/cyndi/cyndi
```

That auto-adds the tap and installs the app — no separate `brew tap` step. To update later:

```sh
brew upgrade --cask cyndi
```

## The idea

Glanceable at rest, out of the way otherwise. See your notes as dots without opening anything; tap one to write. Clean, hand-drawn look. Built for the Mac App Store — public APIs only.

## How it works

- **Dots** — one per note, pinned at the notch, visible across Spaces. Shown only when you have at least one note.
- **Expand** — click a dot or press `⌘⇧Space` to open the note editor. `⌘1` / `⌘2` switch notes while open.
- **Menu bar** — always-available home and empty-state entry point. Toggle **Show checklist dots** to hide the dots at rest; they reappear whenever you open the editor.
- Accessory app: no Dock icon, optional launch-at-login (off by default).
- Notes are stored **locally** — no Reminders / iCloud sync.

## Constraints

- Public, sandbox-safe APIs only — no Accessibility, no private SkyLight/`CGSSpace`.
- Trade-off: dots **hide** over other apps' native fullscreen and the lock screen. That's the price of App Store eligibility, and it's intentional.

## Status

Shipping via Homebrew (see **Install**), distributed as a signed + notarized app outside the App Store. Decisions and open questions live in the GitHub issues (see the map, [#1](https://github.com/marufahmed-afk/cyndi/issues/1)). Feasibility findings: `docs/research/dots-feasibility.md`.

- **Minimum macOS**: 14
- **Stack**: SwiftUI / AppKit
