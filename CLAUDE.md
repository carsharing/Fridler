# Fridler

iOS app + WidgetKit widget, sideloaded with AltStore (free Apple ID). There is
no Mac here: CI on GitHub Actions (`macos-26`) is the compiler. Push, then read
the workflow logs.

- `project.yml` (XcodeGen) is the project; the `.xcodeproj` and Info.plists are generated.
- Shared code lives in `Shared/` and is compiled into both the app and the widget.
- Additive-only: new `FridgeDoc` fields get defaults and are decoded with
  `c.value(_:default:)`; never rename or remove fields or enum raw values.
- Snapshot tests render scenes to `Snapshots/Output`; approved ones live in
  `Snapshots/Reference`. Name new snapshots with the version that adds them.
- Keep the flat cartoon style: `Palette.ink` outlines, flat fills, hard offset shadows,
  sizes as multiples of `SceneLayout.unit`.
- Widgets only support buttons: in-widget doodling is tap-based (App Intents).
- Ship a version: bump `MARKETING_VERSION` in `project.yml`, add a CHANGELOG
  section, update ROADMAP status, push to `main`, then tag `vX.Y.Z`.
