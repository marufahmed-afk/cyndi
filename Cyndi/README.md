# Cyndi — spike

Vertical-slice spike proving the hard parts of the notch-dots concept on
public, sandbox-safe APIs: **dots hug the notch → click/⌘⇧Space expands the
panel → one editable note**. Resolves issue #7.

This is a spike, not the app. It proves the technical slice end to end; it is not
an MVP (no persistence, no note lifecycle, no multi-monitor policy — those are the
map's remaining fog).

## Run

```sh
cd Cyndi
swift run
```

Runs as an accessory app (no Dock icon). A row of dots appears at the notch;
press **⌘⇧Space** or click a dot to expand the editor. `↵` adds an item,
click an item to toggle it, `← →` switch notes, `Esc` / click-outside closes.

## What it proves (per the locked decisions)

- **Public-API notch presence** (#2): borderless `.nonactivatingPanel` at
  `.statusBar` level, `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary,
  .ignoresCycle]`, `orderFrontRegardless()`; geometry from `auxiliaryTopLeftArea`
  / `safeAreaInsets`. No Accessibility, no private SkyLight/CGSSpace.
- **Two-panel split** (#3): always-on non-key dots panel + separate key-capable
  editor panel. Vendored geometry/panel from DynamicNotchKit (see `Vendored/NOTICE.md`).
- **Visual spec** (#4): 15pt filling dots, groups anchored `center ± 110`, crown
  selected stroke, `#05080A` panel grown-down, Caveat + Kalam, hand-drawn
  checkbox + wobbling-tick + crown as vector paths, print-process palette.
- **Interaction** (#5): one dot = one note; click toggles/switches; ⌘⇧Space
  toggles; Esc / click-outside collapse.

## Stack

SwiftUI / AppKit, macOS 14+, SwiftPM executable. Carbon `RegisterEventHotKey`
for the global hotkey (public, no Accessibility). Fonts bundled (Caveat, Kalam — OFL).
