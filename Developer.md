# Build Dragon Go Client

Use Xcode 27 with iOS 15 or later. From this directory run `./bootstrap.sh`, then open `DGSPhone.xcworkspace` and select **DGS Debug**. Dependencies and Ruby tools are installed inside `.tools`; no sudo, system Ruby installation, or system developer-directory change is required.

The app declares a single UIKit scene in `DGSPhone-Info.plist`. `DGSSceneDelegate` owns the storyboard window and forwards scene foreground/background transitions to the existing application delegate. Keep this configuration when changing startup code: apps linked with the iOS 27 SDK are terminated at launch on iOS 27 if they have not adopted the scene lifecycle.

The bootstrap installs the pinned CocoaPods dependencies, applies SDK fixes to Reachability/MKNetworkKit, and builds Fuego 1.1 directly from its upstream source. Fuego is built for arm64 iPhones and arm64/x86_64 simulators; Boost 1.58 is used as headers only. Both upstream archives are verified with committed SHA-256 checksums. Downloads, sources, objects, and frameworks stay under ignored `.build/fuego`, and an unchanged build recipe reuses them immediately. Run bootstrap again if Pods or `.build` are removed.

The compatibility work is derived from Justin Weiss's historical `fuego-framework` project, but bootstrap no longer clones that repository or downloads its S3-hosted binaries. The maintained recipe is `scripts/build-fuego.py`. It validates the expected Fuego 1.1 source layout before applying the compiler fixes, compiles the same 102 source files for all supported architectures, and writes `.build/fuego/manifest.json` with source checksums, product checksums, the deployment target, and Xcode version.

For an existing Pods checkout, only these steps are needed:

```sh
python3 scripts/prepare-legacy-pods.py
python3 scripts/build-fuego.py
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -workspace DGSPhone.xcworkspace -scheme 'DGS Debug' \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

For a release build, start from the signed release tag, run `./bootstrap.sh`, and archive with the shared **DGS Release** scheme. Pass the CI build number as `CURRENT_PROJECT_VERSION`; the default for local builds is 137. Builds never increment or otherwise modify the source plist. Preserve the exported IPA, dSYM, Git commit, `.build/fuego/manifest.json`, effective `CURRENT_PROJECT_VERSION`, and CI image identifier together as the release provenance. The archived IPA/dSYM are the authoritative artifacts; rebuilding the tag is expected to be behaviorally equivalent rather than byte-for-byte identical after signing.

Device signing uses the configured Apple Development identity and team `3WR88837J5`. Select a development device in Xcode and run. Do not change macOS security permissions to work around signing failures.

# Push notifications

`Config.h` selects these HTTPS services:

| Configuration | Bundle ID | Backend | APNs |
| --- | --- | --- | --- |
| Debug | `net.uberweiss.DGS.dev` | `dragon-go-push-3wr88837j5.fly.dev` | Development |
| Adhoc | `net.uberweiss.DGS.dev` | `dragon-go-push-3wr88837j5.fly.dev` | Development |
| Release (TestFlight and App Store) | `net.uberweiss.DGS` | `dragon-go-push-production-3wr88837j5.fly.dev` | Production after distribution export |

The legacy configuration named **Adhoc** is development signed; it is not Apple's Ad Hoc distribution method. Actual Ad Hoc distribution and TestFlight use production APNs. The production service and APNs key are already configured for `net.uberweiss.DGS`.

On launch/login the app requests notification permission, sends its DGS session to the push server, stores the returned bearer token in a host/player-specific Keychain entry, and registers its APNs token. Game requests wait until registration completes and receive the current bearer token when sent. Logout removes the device registration. Foreground notifications refresh games; tapping a notification returns to the game list. The DGS session itself still uses the existing iOS cookie storage.

For development, sign in with a test user, allow notifications, background the app, then invoke the server's authenticated sandbox test route for the registered device. For TestFlight, use a real turn played by a second DGS account: the production server deliberately does not expose the sandbox test route. Confirm the alert appears and tapping it opens the games screen. Simulator `simctl push` only tests local UI handling; it is not proof of real APNs delivery.

The server's README documents deployment, secrets, polling, and integration checks. Keys, cookies, and bearer tokens must never be committed or printed in logs.

# TestFlight

The initial beta uses the Release scheme and production backend. This verifies the actual release notification path and allows the same tested build to become an App Store release candidate. Uploading to TestFlight does not submit an App Store release.

Archive and upload from the workspace after bootstrap:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -workspace DGSPhone.xcworkspace -scheme 'DGS Release' \
  -destination 'generic/platform=iOS' -archivePath .build/testflight/DGS.xcarchive \
  -allowProvisioningUpdates archive
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -exportArchive -archivePath .build/testflight/DGS.xcarchive \
  -exportOptionsPlist scripts/ExportOptions-TestFlight.plist \
  -exportPath .build/testflight/export -allowProvisioningUpdates
```

Use a new `CURRENT_PROJECT_VERSION` for every upload. Automatic signing uses Apple Development when archiving and distribution signing during export; do not force an Apple Distribution identity on the automatically signed archive target. Check the exported app's entitlements, not just the archive: `aps-environment` must be `production`, `get-task-allow` false, and the application identifier must end in `net.uberweiss.DGS`.

Start with internal testing. External testers require Apple's beta review and completed Test Information. TestFlight replaces the App Store installation of the same bundle ID; the development `.dev` app can coexist. TestFlight purchases use Apple's StoreKit sandbox even when the app connects to our production backend. Future purchase validation must distinguish sandbox transactions and must not turn them into paid production entitlements.

Device acceptance checks before wider testing:

- Upgrade an existing App Store install, and also test a fresh install. Apple warns that the transferred app's team prefix changed from `UH58U5BNM8` to `3WR88837J5`, so historical Keychain entries are inaccessible. DGS login currently uses cookies; push bearer credentials are recreated from the DGS session. Verify login recovery rather than assuming the transfer is invisible.
- Allow notifications, background the app, and have a second account play a turn. Verify one notification, badge, and tap navigation. Repeat with the app terminated and in the foreground.
- Check logout, account switching, notification permission denied/re-enabled, and a subsequent TestFlight update. Confirm no notifications for a logged-out account.
- Verify Fuego scoring and normal play on a phone. A successful archive or APNs acceptance response does not prove these behaviors.

## Future backend experiments

Create an isolated staging Fly app and database before testing incompatible backend changes. Give it its own session encryption key and queues, and test migrations there. It still polls real DGS accounts, so isolation does not remove upstream load or account-side effects.

Do not merely add a same-bundle staging configuration: the two databases can retain the same production APNs token and both send notifications. The current client also stores its device registration ID in a single defaults key. A same-bundle staging lane first needs host-scoped registration IDs and a reliable, retryable handoff that retires the previous host's registration; failure and offline switching need tests. Alternatively, a separate beta bundle ID/APNs topic gives clean separation and side-by-side installation, at the cost of a separate App Store Connect app and purchase setup. A staging-pointed build must never be promoted unchanged to the production App Store release.

For small beta features on a compatible production backend, use server-authorized account cohorts and a kill switch. Do not trust a client-provided beta header as authorization. Add this when there is an actual feature to gate; no feature-flag or StoreKit infrastructure is implemented yet.

## App appearance

The shared light/dark palette is in `Assets.xcassets`. Edit the **Dark** variant
in Xcode's color editor (or the luminosity-dark components in `Contents.json`):

- `AppBackground`: launch screen, plain lists, game canvas, and window background.
- `AppGroupedBackground`: grouped forms; keep its dark value equal to `AppBackground`.
- `AppSurface`: grouped rows and the game controls, including the bottom safe area.

Assign cell backgrounds in the storyboard, including loading prototypes, so initial
insertion animations use the right color. Use semantic label colors for text.
The board, stone artwork, capture labels, and translucent dark message/spinner
backdrops intentionally retain their own colors. The acknowledgements HTML uses
transparent backgrounds and adaptive text/link colors.

For appearance review, cold-launch in both modes, switch to All Games before it
has loaded, and open login, Start a Game, creation/pickers, waiting room/join,
invitations, game/messages, and acknowledgements. Also switch appearance while a
screen is open. iOS can cache an old launch snapshot after an app update.
