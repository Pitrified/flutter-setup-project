# 09 - Split CEFR text into guidance + description

Part of phase 09 (UI tweaks and small functionality). Restores the detailed
CEFR copy that was trimmed away, but splits it across two fields with distinct
jobs in the picker.

## Background

`CefrLevel.description` was shortened to one-word fragments ("Beginner.",
"Elementary.", ...). That reads well in the chip tooltip and the Settings
dropdown, but the picker bottom sheet lost the guidance that helps a user
choose a level. This plan keeps a short label and adds back the detailed copy
as a separate field.

## Goal

After this change:

- `CefrLevel` exposes two getters:
  - `description` - short label (the current trimmed text, e.g. "Beginner.").
  - `guidance` - the detailed sentence (e.g. "Beginner. Basic phrases,
    introductions, simple needs.").
- In the chat flow, only the **short** label shows: the CEFR chip stays `A1`,
  and the picker rows show `displayName` + `guidance` as the subtitle.
- Descriptive text shows only in the **Settings** interface: the default-level
  dropdown keeps `displayName - description` (e.g. `A2 - Elementary.`).

## Placement summary

| Surface | Text shown |
|---------|------------|
| Chat AppBar chip (`_CefrAction`) | `displayName` only (`A2`) - unchanged |
| Picker rows (opened from chat) | title `displayName`, subtitle `guidance` |
| Settings default-level dropdown | `displayName - description` - unchanged |

No description bar is added to the conversation screen.

## Non-goals

- No change to the tutor prompt. CEFR feeds the model as `displayName`
  (`"A1"`), not these texts; this is UI-only copy.
- No change to the picker interaction: tapping a level still applies it and
  closes the sheet immediately (one tap, no confirm step).
- No new widget on the conversation screen.

## Files touched

Modified:

- `lib/models/cefr_level.dart`
  - Keep `description` as the short label; update its doc comment to "Short
    label, e.g. for the Settings dropdown and the chip tooltip."
  - Add `String get guidance` with the detailed sentences (restore the
    pre-trim copy):
    - a1: "Beginner. Basic phrases, introductions, simple needs."
    - a2: "Elementary. Familiar topics, short routine exchanges."
    - b1: "Intermediate. Travel situations, opinions on familiar topics."
    - b2: "Upper-intermediate. Detailed discussion on a wide range of topics."
    - c1: "Advanced. Fluent, flexible, nuanced expression."
    - c2: "Mastery. Effortless, precise, near-native command."

- `lib/screens/conversation/widgets/cefr_picker_sheet.dart`
  - Single change: the row `subtitle` switches from `level.description` to
    `level.guidance` so the picker shows the detailed copy. Everything else
    (one-tap `onTap` pop, title, check mark) stays as-is.

Unchanged (called out so the intent is explicit):

- `lib/screens/conversation/conversation_screen.dart` - no level bar; the
  `_CefrAction` chip keeps showing `displayName` only. Its tooltip already
  reads `CEFR level: ${current.description}` (only visible on long-press); left
  as-is since it is not part of the at-a-glance chat UI.
- `lib/screens/settings/settings_screen.dart` - the dropdown already shows
  `${level.displayName} - ${level.description}`; this is the intended place for
  descriptive text, so no edit needed.

New:

- (Optional) extend the existing widget test for the conversation screen, or
  add `test/screens/conversation/widgets/cefr_picker_sheet_test.dart`,
  asserting the row subtitle now shows `guidance`. Skip if no harness fits.

## Behaviour contract

- The picker still returns the tapped level and closes; `_CefrAction`'s
  `picked == current` guard is unaffected.
- `description` stays the short text used by the Settings dropdown (and the
  chip tooltip); the picker rows use `guidance`.

## Acceptance criteria

- `flutter analyze` clean.
- `test/models/cefr_level_test.dart` extended: `guidance` is non-empty for
  every level (mirror of the existing `description` test).
- Manual smoke: while chatting, the chip shows only `A2`; open the picker -
  each row shows the detailed guidance under the level label; tap a level and
  the sheet closes. In Settings, the default-level dropdown shows
  `A2 - Elementary.`.

## Commit message (suggested)

```
feat(cefr): split level copy into guidance + description

- CefrLevel keeps a short `description` and adds a detailed `guidance`.
- The picker shows guidance per row and a live description above the list
  that updates as the selection changes; a Set level button commits.
- Chip tooltip and Settings dropdown keep using the short description.
```
