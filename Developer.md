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

Boost and Fuego are included as frameworks using some simple local
podspecs. Because they both take a long time to compile and take up a
lot of space in the repo, I have a separate project called
([fuego-framework](https://github.com/justinweiss/fuego-framework))
that compiles them into .frameworks that can be easily downloaded and
included into this project. This way, they can also be managed using
CocoaPods, which is really convenient.
