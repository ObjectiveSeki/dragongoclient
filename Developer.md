# Build Dragon Go Client

Use Xcode 26 with iOS 15 or later. From this directory run `./bootstrap.sh`, then open `DGSPhone.xcworkspace` and select **DGS Debug**. Dependencies and Ruby tools are installed inside `.tools`; no sudo, system Ruby installation, or system developer-directory change is required.

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

`Config.h` points to `dragon-go-push-3wr88837j5.fly.dev` over HTTPS. The prepared server configuration uses sandbox APNs with the Debug bundle ID `net.uberweiss.DGS.dev`. Production/TestFlight builds use `net.uberweiss.DGS` and require a separately configured production APNs service/key; the sandbox service rejects that topic.

On launch/login the app requests notification permission, sends its DGS session to the push server, stores the returned bearer token in a host/player-specific Keychain entry, and registers its APNs token. Game requests wait until registration completes and receive the current bearer token when sent. Logout removes the device registration. Foreground notifications refresh games; tapping a notification returns to the game list. The DGS session itself still uses the existing iOS cookie storage.

To verify after deployment: sign in with a test user, allow notifications, background the app, then invoke the server's authenticated sandbox test route for the registered device. Confirm the alert appears and tapping it opens the games screen. Simulator `simctl push` only tests local UI handling; it is not proof of real APNs delivery.

The server's README documents deployment, secrets, polling, and integration checks. Keys, cookies, and bearer tokens must never be committed or printed in logs.
