# Handoff: Cyndi — notch dots + focus-mode note panel (POC)

## Overview
Cyndi is a sandbox-safe, Mac App Store–eligible macOS **menu-bar accessory app** (no Dock icon). Its hero surface is a row of small dots hugging the MacBook notch — one dot per note. Clicking a dot, or pressing **⌘⇧Space**, dims the desktop and drops a small black panel directly beneath the notch with the caret already blinking, so the user can type a note or stack a checklist immediately. Notes are stored **locally only** (no Reminders, no iCloud).

This bundle documents the approved POC design (draft two, "all black") plus the earlier draft kept for reference.

## About the Design Files
The files in this bundle are **design references authored in HTML** — interactive prototypes that demonstrate intended look, motion and behavior. They are **not production code to port**. The task is to recreate these designs natively in the target environment: for this product that means **SwiftUI/AppKit on macOS 14+** (borderless `NSPanel`/`NSWindow` at the notch, `NSStatusItem` accessory app, `LSUIElement`), following the codebase's existing patterns. Treat every measurement below as the spec; treat the HTML as the visual proof.

Public, sandbox-safe APIs only — no Accessibility API, no private SkyLight/CGSSpace. The accepted trade-off (dots hidden over other apps' native fullscreen and over the lock screen) is designed for, not worked around; see *Fullscreen fallback*.

## Fidelity
**High-fidelity.** Colors, type sizes, geometry, timings and copy below are final for the POC. Recreate the panel and dot row pixel-accurately at 1× logical points (the prototype's px map 1:1 to macOS points). The surrounding "desktop / menu bar / notch" chrome in the prototype is **stage dressing only** — it simulates macOS and must not be built.

## Approved configuration
The prototype exposes a few switches; the chosen build target is:

- **Dot shape:** filling dot — outlined circle in the note color, filled from the bottom in proportion to checklist completion.
- **Selected-dot effect:** `crown` — a hand-drawn pen stroke tucked under the selected dot, pointing into the panel. (Secondary options in the prototype: `bright` = brightened color only, `halo`, `lift`. Ship `crown`; keep `bright` as fallback if the stroke reads noisy at 1×.)
- **Dot diameter:** 15 pt.
- **Hover info card:** OFF. No tooltip on hover.
- **Unselected dot dim:** 0.4 opacity while the panel is open.
- **Panel width:** 420 pt.

## Screens / Views

### 1. Collapsed — dot row at the notch (default, always-on)
**Purpose:** glanceable status. One dot per note, ordered most-recently-touched first.

**Layout**
- A borderless, click-through-except-on-dots window pinned to the menu-bar band, height **30 pt** (menu-bar height), full screen width.
- Two groups anchored to the notch edges, **not** centered as one row (critical: group widths differ, so centering misaligns them):
  - Left group: right edge at `screenCenter − 110 pt`, laid out right-to-left.
  - Right group: left edge at `screenCenter + 110 pt`, laid out left-to-right.
  - Notch cutout is 196 pt wide → 12 pt clearance each side. No dot may cross the cutout edge.
- Each dot occupies a 20 × 30 pt hit box (≥ 20 pt target; enlarge to 28 pt tall if AppKit hit-testing allows), vertically centered, **10 pt gap** between dots.
- Max **6 dots** visible (3 left, 3 right). Remainder collapses into an overflow pill at the right end.

**Dot (filling dot)**
- 15 × 15 pt circle, `border: 1.4 pt solid <noteColor>`.
- Fill: vertical fill from the bottom, `<noteColor>` up to `completion%`, `rgba(243,242,242,0.09)` above it. Completion = done items ÷ total items; a note with no items reads empty.
- Collapsed state: all dots at full opacity, stroke in the note color.
- Idle motion in the prototype (1 pt vertical breathe, 6 s) is optional flourish — drop it if it costs a redraw.

**Overflow pill**
- Height 15 pt, horizontal padding 6 pt, `1.3 pt dashed rgba(243,242,242,0.45)`, hand-drawn radius (below), label `+N` in Kalam 11 pt, `rgba(243,242,242,0.70)`.
- Hover reveals a 186 pt list panel below it: each row = 11 pt filling dot + note title (Kalam 13 pt, `rgba(243,242,242,0.86)`), 8 pt row gap, 10/12 pt padding, background `#05080A`, `1.4 pt solid rgba(243,242,242,0.22)`, hand-drawn radius, shadow `0 8 22 rgba(0,0,0,0.55)`. Clicking a row opens that note.
- **Open question for build:** overflow rule beyond ~8 notes (scroll vs. archive) is unresolved in spec; list is fine for the POC.

### 2. Expanded — focus mode panel
**Purpose:** capture. Opens on ⌘⇧Space or a dot click; the caret is already live.

**Window / surface**
- Width **420 pt**, centered on the notch (`x = screenCenter − 210`), top edge at `y = 30 pt` (flush under the menu-bar band, so it visually continues the notch).
- Background **`#05080A`** — identical to the notch black, so the panel reads as the notch growing downward. **No top border, no visible outline**; corner radius `0 0 20 20 pt`. Elevation: `0 26 50 rgba(0,0,0,0.6)` plus a 1 pt inner hairline `rgba(243,242,242,0.08)`.
- A 196 × 4 pt block of `#05080A` sits at the panel's top center to erase the seam under the notch cutout.
- Padding: 18 pt top, 20 pt sides, 15 pt bottom.
- Entry: fade `0 → 1` over 160 ms plus `translateY(−12 pt) scale(0.985) → identity` over 180 ms, `cubic-bezier(0.2, 0.9, 0.3, 1.2)`. Exit is the reverse.

**Desktop dim (focus mode)**
- Full-screen overlay `rgba(6,9,11,0.68)` + 1.5 pt background blur, 180 ms fade. Sits **below** the dot row and panel, above everything else.
- Menu bar drops to 0.35 opacity while open.
- Clicking the dim closes the panel and discards the empty draft.

**Panel contents (top to bottom)**
1. **Header row** — baseline-aligned, 12 pt gap, 4 pt bottom margin.
   - Left: 11 pt filling dot (same treatment as the notch dot, 1.4 pt stroke) + note title in **Caveat 28 pt / line-height 1**, `#F3F2F2`, letter-spacing 0.01em.
   - Right: progress count `"1/3"` in Kalam 12 pt, `rgba(243,242,242,0.45)`.
2. **Position line** — Kalam 11.5 pt, `rgba(243,242,242,0.30)`, 8 pt bottom margin: `note 1 of 8 · last touched first`.
3. **Item rows** — one per checklist item, height **34 pt**, 2 pt gap, 11 pt gap between box and text, whole row is the tap target.
   - Checkbox: 17 × 17 pt, `1.5 pt solid`; unchecked stroke `rgba(243,242,242,0.50)` on transparent; checked stroke = note color on `rgba(243,242,242,0.05)`. Each box is rotated by `((index % 3) − 1) × 1.5°` so the column looks hand-drawn.
   - Checkmark: hand-drawn SVG path in the note color, 2.1 pt round cap — a wobbling tick, not the system glyph. Path (16 × 16 box): `M2.6 8.9 C4.2 10.2 5.1 11.6 6.2 13.4 C8.1 8.9 10.4 5.2 14 1.9`.
   - Label: Kalam 17 pt / 1.2. Open `#F3F2F2`; done `rgba(243,242,242,0.40)` + strikethrough 1.5 pt.
4. **Draft row** — same 34 pt geometry. Empty checkbox is `1.5 pt dashed rgba(243,242,242,0.28)`, rotated −1.4°. Text field is borderless, transparent, Kalam 17 pt, `#F3F2F2`, placeholder `start typing…`. While empty, a 1.6 × 20 pt caret in the note color blinks at 1.05 s (step-end, 50/50 duty).
5. **Progress bar** — 13 pt top margin, height 7 pt, `1.3 pt solid rgba(243,242,242,0.24)`, hand-drawn radius, inner fill = note color at `completion%`, 180 ms width transition.
6. **Footer hints** — 12 pt top margin, Kalam 11.5 pt, `rgba(243,242,242,0.40)`, space-between: `↵ new item · ← → switch note` / `⌘⇧Space to close · saved locally`.

**Note switching happens on the dots, not in the panel.** There is no tab bar, no list, no chrome inside the panel.
- Dot row stays visible and interactive while the panel is open.
- Selected dot: `crown` stroke beneath it — hand-drawn arc in the note color, 18 pt wide, 2 pt round-cap stroke, sitting at the bottom of the 30 pt hit box, fading in over 160 ms. Path (20 × 8 box): `M1.5 6.4 C6 6.9 13.5 6.6 18.4 6.1`.
- Unselected dots: opacity 0.4, stroke `rgba(243,242,242,0.35)` (fill still shows progress).
- Clicking another dot switches the active note **without leaving focus mode**; the caret refocuses immediately and any unsubmitted draft is dropped.

### 3. Fullscreen fallback (the accepted trade-off)
When another app is in native fullscreen, the dots cannot be drawn over the notch with public APIs.
- Dot row hides (180 ms fade); the menu-bar band slides up out of view with it.
- Moving the cursor to the **top 16 pt** of the screen reveals the menu bar and the dots again (system behavior) — no polling of window state beyond public notifications.
- ⌘⇧Space still opens the panel.
- Onboarding/help copy for this state (prototype shows it as a card, 296 pt wide, `#05080A`, `1.6 pt solid rgba(243,242,242,0.22)`, hand-drawn radius, title Caveat 22 pt in `#F2C200`, body Kalam 14 pt / 1.5 `rgba(243,242,242,0.72)`): "Dots are hidden here — over another app's native fullscreen, sandbox-safe windows can't sit on the notch. Nudge the cursor to the top edge to reveal them — or just press ⌘⇧Space."

## Interactions & Behavior
| Trigger | Result |
| --- | --- |
| **⌘⇧Space** (global hotkey) | Toggle panel. Opening dims the desktop, opens the last-touched note, focuses the field. |
| **Esc** | Close panel, discard the in-progress draft. |
| **Click a dot** | Open panel on that note (or switch to it if already open); field refocuses. |
| **Click overflow row** | Same as clicking a dot. |
| **Hover overflow pill** | Reveal hidden-note list. (Dot hover shows nothing — deliberate.) |
| **← / →** while open and draft empty | Previous / next note, wrapping. |
| **↵** in the field | Append item to the active note, clear the field, keep focus. Blank input is a no-op. |
| **Click an item row** | Toggle done; the dot's fill and the progress bar update in the same frame. |
| **Click the dim** | Close. |

Timings: dot fades and dim 180 ms ease; panel 160/180 ms with `cubic-bezier(0.2, 0.9, 0.3, 1.2)`; selected-dot stroke 160 ms; fill and progress-bar changes 180 ms ease.

Not designed yet (open in spec): dot drag-reorder, note deletion/archive lifecycle, multi-monitor policy (which display owns the dots), persistence mechanism.

## State Management
- `notes: [{ id, title, color, items: [{ text, done }] }]` — ordered most-recently-touched first; local persistence only (SQLite/Core Data or a JSON file in the app container — undecided in spec).
- `activeNoteID` — the note the panel shows; defaults to `notes.first`.
- `isOpen` — panel visibility; drives the dim, menu-bar opacity and dot selection state.
- `draft: String` — uncommitted text; cleared on commit, note switch, Esc and close.
- `hoverOverflow: Bool`.
- `isOtherAppFullscreen`, `menuBarRevealed` — fallback state.
- Derived: `completion(note) = done ÷ total` (0 when empty), `visibleDots = notes.prefix(6)`, `overflow = notes.dropFirst(6)`.
- No network, no permissions prompts, no Accessibility.

## Design Tokens
**Note colors** (user-picked per note; the palette is the print-process set from the project's design system)
| Token | Hex |
| --- | --- |
| Print yellow | `#F2C200` |
| Process cyan | `#0088B0` |
| Process magenta | `#D6006C` |
| Green | `#4F9D69` |
| Violet | `#7B5EA7` |

**Surfaces & ink**
| Role | Value |
| --- | --- |
| Notch + panel black | `#05080A` |
| Panel ink | `#F3F2F2` |
| Ink, secondary | `rgba(243,242,242,0.45)` |
| Ink, tertiary / hints | `rgba(243,242,242,0.30–0.40)` |
| Done item ink | `rgba(243,242,242,0.40)` |
| Hairlines | `rgba(243,242,242,0.08 / 0.22 / 0.24 / 0.28 / 0.50)` |
| Desktop dim | `rgba(6,9,11,0.68)` + 1.5 pt blur |
| Unfilled dot interior | `rgba(243,242,242,0.09)` |

**Type** — hand-drawn voice, ~90% Excalidraw
- Titles: **Caveat** 600 — 28 pt (panel title), 22 pt (fallback card).
- Body/UI: **Kalam** 400 — 17 pt (items, field), 13 pt (overflow rows), 12 pt (progress count), 11.5 pt (hints, position line), 11 pt (overflow pill).
- Native build: bundle Caveat + Kalam (both SIL OFL), or substitute the codebase's approved handwriting faces. Never a system sans in the panel.

**Geometry**
- Menu-bar band 30 pt · notch cutout 196 pt · notch clearance 12 pt · dot gap 10 pt · dot 15 pt · dot hit box 20 × 30 pt.
- Panel 420 × auto, radius `0 0 20 20`, padding 18/20/15, row height 34 pt, item gap 2 pt, box↔text gap 11 pt.
- Hand-drawn radii (use these literal asymmetric values, they are what makes boxes look sketched):
  - Small (checkbox, pill, progress bar): `6px 4px 7px 4px / 4px 7px 4px 6px`
  - Medium (tooltip / list): `12px 8px 14px 9px / 8px 13px 9px 12px`
  - Card (fallback note): `16px 9px 18px 10px / 9px 17px 10px 16px`
  - In SwiftUI these need a custom `Shape` (per-corner rx/ry) or a vector asset — a uniform `cornerRadius` loses the effect.
- Shadows: panel `0 26 50 rgba(0,0,0,0.6)`; floating lists/cards `0 8 22 rgba(0,0,0,0.55)`.
- Rotations for the hand-drawn feel: checkbox `((i % 3) − 1) × 1.5°`; draft checkbox `−1.4°`.

## Assets
No images. The two hand-drawn vectors (checkmark, selected-dot stroke) are inline SVG paths quoted above — reproduce as vector paths, not font glyphs. Icons elsewhere in the product should follow the project's system (Phosphor, duotone). Fonts: Caveat, Kalam (Google Fonts, OFL).

## Files
- `Cyndi Notch POC v2.dc.html` — **the approved design.** Black panel, dots as the switcher, filling dots, selected-dot effect variants, fullscreen fallback. Open in a browser; press ⌘⇧Space (or click the desktop) to enter focus mode. The right-hand rail and the page header are documentation scaffolding, not app UI.
- `Cyndi Notch POC.dc.html` — draft one, kept for reference: grey `#1B1A19` panel, in-panel note tabs, three alternate dot languages (progress ring / filling dot / tally marks) and three panel takes.
- `support.js` — runtime for the two prototypes (so they open offline). Not part of the design.
- `_ds/` — the Broadsheet design system stylesheet the documentation pages are set in. It styles the **surrounding page**, not the app; only the process color palette carries into the app.
