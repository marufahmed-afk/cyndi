# cyndi

A tiny macOS app that lives at the notch. A row of **dots** hugs the notch — one per note — and **expands into sticky-notes / todos** when you click or hit a hotkey.

## The idea

Glanceable at rest, out of the way otherwise. See your notes as dots without opening anything; tap one to write. Clean, hand-drawn look. Built for the Mac App Store — public APIs only.

## How it works

- **Dots** — one per note, pinned at the notch, visible across Spaces. Shown only when you have at least one note.
- **Expand** — click a dot or press `⌘⇧Space` to open the note editor. `⌘1` / `⌘2` switch notes while open.
- **Menu bar** — always-available home and empty-state entry point.
- Accessory app: no Dock icon, optional launch-at-login (off by default).
- Notes are stored **locally** — no Reminders / iCloud sync.

## Constraints

- Public, sandbox-safe APIs only — no Accessibility, no private SkyLight/`CGSSpace`.
- Trade-off: dots **hide** over other apps' native fullscreen and the lock screen. That's the price of App Store eligibility, and it's intentional.

## Status

Spec + spike. Decisions and open questions live in the GitHub issues (see the map, [#1](https://github.com/marufahmed-afk/cyndi/issues/1)). Feasibility findings: `docs/research/dots-feasibility.md`.

- **Minimum macOS**: 14
- **Stack**: SwiftUI / AppKit
