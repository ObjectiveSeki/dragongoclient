# Development

Read the [AI policy](AIPolicy.md) before contributing.

## Building

You need Xcode 27, Ruby, and Python 3.

The scripts default to `/Applications/Xcode.app`. If yours is installed elsewhere,
set `DEVELOPER_DIR` before building or testing, for example:

```sh
export DEVELOPER_DIR=/Applications/Xcode-27.2.0.app/Contents/Developer
```

```sh
./bootstrap.sh
open DGSPhone.xcworkspace
```

Select **DGS Debug**, choose an iPhone simulator, and run. For a physical phone,
select your own development team and adjust signing and bundle IDs as needed.

Bootstrap installs CocoaPods dependencies and builds Fuego from verified upstream
sources. Everything stays in `.tools`, `Pods`, and `.build`; no sudo is needed.
Run bootstrap again if you remove dependencies or build products.

## Testing

After bootstrap:

```sh
python3 scripts/test-push-registration.py
python3 scripts/test-server-trust.py
```

These check registration callbacks and certificate handling locally. Test changed
behavior in the app too. Real push delivery needs a device, configured push service,
and APNs credentials; simulator notifications do not verify delivery.

## Push backend

Push notifications use a new, separately maintained backend whose source is
currently private. Its source and service credentials are not needed to build
the client or run the checks above.

`Config.h` selects the push service. Debug uses development APNs; Release uses the
production service. Use test accounts for development and keep credentials out of Git.
