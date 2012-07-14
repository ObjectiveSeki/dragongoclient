This project uses a software project called "CocoaPods" to manage its
dependencies. This makes the dependencies much easier than the git
submodule method I was previously using. On a recent Mac OS, you
should be able to run `bootstrap.sh` to get all the dependencies
installed. If you're running into permissions issues, you can pass
bootstrap.sh the `--sudo` parameter to run certain commands with sudo.

You should just be able to open the generated `DGSPhone.xcworkspace`,
build the main DGSPhone target, and everything else should just
work. Make sure to open the .xcworkspace file that CocoaPods
generates, and not the .xcproject.

If you'd like to know more about CocoaPods, the
[wiki](https://github.com/CocoaPods/CocoaPods/wiki) is the best place to look.

To build boost, I just followed this tutorial:
http://www.danielsefton.com/2012/03/building-boost-1-49-with-clang-ios-5-1-and-xcode-4-3/
