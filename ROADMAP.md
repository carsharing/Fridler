# Fridler roadmap

A doodle hanging on your iPhone home screen, held by a magnet on a fridge door.
Free route only: GitHub Actions builds the app, AltStore installs it with a
free Apple ID. Nobody needs Xcode.

## Ground rules

- **Additive versions.** Each version adds options; it doesn't rework what
  already works. Saved data only grows (new fields have defaults, nothing is
  renamed or removed), so updating never wipes the fridge.
- **Pictures as regression tests.** CI renders the widget at every size.
  Approved pictures go in `Snapshots/Reference` and any later change to them
  fails the build.
- **Every version is a tag and an IPA**, so the previous one can always be
  reinstalled.
- **Widgets can't take finger drawing.** Apple only allows buttons in widgets.
  Freehand drawing happens in the app; on the widget, doodling is tap-based
  (pixels, mazes, coloring, dots, knobs).

## Decisions so far

| Topic | Decision |
|---|---|
| Phone | iOS 27.2. App targets iOS 18+. Clear/Tinted home screens supported. |
| AltStore | One free app slot left: Fridler takes it (app + widget = 2 App IDs). |
| Repo | `carsharing/Fridler`, public. Versions pushed straight to `main`. |
| Name / language | Fridler, English. |
| Widget sizes | Small, medium and large; the drawing adapts when you resize. |
| Doodle modes | Every mode is an option the user picks. |
| App drawing vs widget taps | Also an option: same paper or separate. |
| Pixel grid | Chunky. |
| Fridge door | User picks the color. |
| Style | Flat cartoon everywhere (thick outlines, flat colors, hard shadows). More "bulbous" wanted: references to come. |
| Papers & mediums | As many as possible, including the odd ones (fogged mirror, sand, cake icing, plaster cast, receipt, blueprint…). |
| Magnets | Change on tap and every few hours. Wacky: dumb wordplay, very serious-looking magnets for silly things, food. Souvenirs from imaginary places. |
| Mazes | Easy, and they change. |
| Coloring pages | Both generated (mandalas, tiles) and hand-made sets. |
| Colors | Crayon box. |
| Bezaz | Stickers, glitter, gold stars, googly eyes, washi tape, stamps… and any other fun extras. |
| Shared family fridge | Yes, but much later (needs a server). |

## Versions

| Version | What you get | Status |
|---|---|---|
| **v0.1 Hello Fridge** | Widget (small/medium/large): fridge door, paper, pizza magnet, sample doodle, your note. Six fridge colors. Clear-mode support (full-color picture, or paper on glass). Diagnostics screen. CI builds the IPA and renders pictures. | ✅ released |
| **v0.2 Draw in the app** | Marker canvas: four colors, three tip sizes, stroke eraser, undo/redo, wipe. Saving hangs it on the fridge. Tapping the widget opens the drawing. | 🛠 building |
| **v0.3 Tap-doodle on the widget** | Chunky pixel grid on the paper: tap to paint, crayon picker, eraser, clear. Option: same paper as the app drawing or its own. | next |
| **v0.4 Magnet roulette** | 12+ magnets (wordplay, serious-for-silly, food, imaginary souvenirs). Tap the magnet to swap; it also changes every few hours. | |
| **v0.5 Papers & pens** | Notebook page, graph paper, sticky note, crayon on kraft, chalkboard, napkin + ballpoint, receipt, blueprint, fogged mirror, sand, cake icing, plaster cast… each with its own pen. | |
| **v0.6 Fill-in pages** | Easy changing mazes (arrow buttons, trail drawn), coloring pages (tap to fill), connect-the-dots. | |
| **v0.7 Bezaz** | Stickers, gold stars, googly eyes, glitter, washi tape, stamps, coffee ring, signature, alphabet letter magnets, and more. Placed in the app. | |
| **v0.8 More toys** | Etch A Sketch knobs, scratch-to-reveal, tic-tac-toe against the fridge. | |
| **v0.9 Fridge gallery** | History of past doodles; several widgets with their own doodle each. | |
| **v1.0 Polish** | AltStore source (updates inside AltStore), icon variants, small fixes. | |
| Later | Shared family fridge between phones. | |
