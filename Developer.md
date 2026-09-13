# Build Dragon Go Client

Use Xcode 26 with iOS 15 or later. From this directory run `./bootstrap.sh`, then open `DGSPhone.xcworkspace` and select **DGS Debug**. Dependencies and Ruby tools are installed inside `.tools`; no sudo, system Ruby installation, or system developer-directory change is required.

The bootstrap installs the pinned CocoaPods dependencies, applies SDK fixes to Reachability/MKNetworkKit, and builds the original Fuego 1.1 sources for both arm64 and x86_64 simulators. Downloads are pinned by commit/checksum. The original device Fuego framework is retained. Boost is needed for headers; the client does not need its legacy binary. The generated simulator framework lives under `.build/simulator-frameworks` and is found automatically by the Xcode project. Run bootstrap again if Pods or `.build` are removed.

For an existing Pods checkout, only these steps are needed:

```sh
python3 scripts/prepare-legacy-pods.py
python3 scripts/build-fuego-simulator.py
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -workspace DGSPhone.xcworkspace -scheme 'DGS Debug' \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Device signing uses the configured Apple Development identity and team `3WR88837J5`. Select a development device in Xcode and run. Do not change macOS security permissions to work around signing failures.

# Push notifications

`Config.h` points to `dragon-go-push-3wr88837j5.fly.dev` over HTTPS. The prepared server configuration uses sandbox APNs with the Debug bundle ID `net.uberweiss.DGS.dev`. Production/TestFlight builds use `net.uberweiss.DGS` and require a separately configured production APNs service/key; the sandbox service rejects that topic.

On launch/login the app requests notification permission, sends its DGS session to the push server, stores the returned bearer token in a host/player-specific Keychain entry, and registers its APNs token. Game requests wait until registration completes and receive the current bearer token when sent. Logout removes the device registration. Foreground notifications refresh games; tapping a notification returns to the game list. The DGS session itself still uses the existing iOS cookie storage.

To verify after deployment: sign in with a test user, allow notifications, background the app, then invoke the server's authenticated sandbox test route for the registered device. Confirm the alert appears and tapping it opens the games screen. Simulator `simctl push` only tests local UI handling; it is not proof of real APNs delivery.

The server's README documents deployment, secrets, polling, and integration checks. Keys, cookies, and bearer tokens must never be committed or printed in logs.
