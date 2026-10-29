# Fridler

A doodle hanging on your iPhone home screen, held up by a magnet on a fridge
door. Flat cartoon style, lots of papers, pens and very silly magnets.

Built for the free route: GitHub Actions compiles it, AltStore installs it
with a free Apple ID. No Xcode, no paid developer account.

See [ROADMAP.md](ROADMAP.md) for where it's going and
[CHANGELOG.md](CHANGELOG.md) for what each version added.

## Install

You need [AltStore](https://altstore.io) on the iPhone and AltServer running
on a computer on the same Wi-Fi.

1. On the iPhone, open the [latest release](https://github.com/carsharing/Fridler/releases/latest)
   in Safari and download **Fridler.ipa**.
2. In AltStore: **My Apps** → **+** → pick `Fridler.ipa` from Downloads.
3. Long-press the home screen → **Edit** → **Add Widget** → **Fridler**, pick a size.

Free Apple ID limits: AltStore re-signs apps every 7 days (keep AltServer
reachable), at most 3 active apps including AltStore, and Fridler uses 2 of
your 10 weekly App IDs (app + widget). Installing a new version over the old
one keeps your fridge.

If the widget says *no shared storage*, open Fridler, scroll to **Behind the
fridge**, tap **Copy report** and paste it in an issue.

## How it's built

| Folder | What's inside |
|---|---|
| `App/` | The app: preview, settings, diagnostics. |
| `Widget/` | The WidgetKit extension. |
| `Shared/` | Code used by both: the saved fridge (`FridgeDoc`), storage, the App Group lookup and every drawing (`Scene/`). |
| `Tests/` | Unit tests and snapshot tests. |
| `Snapshots/Reference/` | Approved pictures; builds fail if these change. |
| `scripts/` | Build, test, snapshot publishing and release notes. |
| `project.yml` | XcodeGen spec; CI generates the Xcode project from it. |

Every push to `main` builds an unsigned IPA (uploaded as a workflow artifact),
runs the tests and force-pushes the rendered pictures to the
[`snapshots`](https://github.com/carsharing/Fridler/tree/snapshots) branch.
Pushing a `v*` tag also publishes a GitHub release with the IPA.

### Sideloading details

AltStore re-signs the app and renames its App Group (the shared folder the app
and widget both read) by appending your team ID. So:

- the build ad-hoc signs the app and the widget with their App Group
  entitlement, which is what tells AltStore to register the group;
- at runtime `AppGroup` looks for the renamed group in `ALTAppGroups`
  (Info.plist), then in the provisioning profile, then falls back to the
  original name.
