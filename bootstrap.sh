#!/bin/sh

if [[ -x `which brew` && ! -d ~/Library/Application\ Support/appledoc ]]; then
    brew install appledoc --HEAD
    ln -sf "`brew --prefix`/Cellar/appledoc/HEAD/Templates" ~/Library/Application\ Support/appledoc
fi

if [ ! -d DGSPhone.xcworkspace ]; then
    gem install cocoapods
    pod setup
    pod install DGSPhone.xcodeproj
else
    pod install
fi
