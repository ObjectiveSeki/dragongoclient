#!/bin/bash

if [[ "$1" == "--sudo" ]]; then
    echo "All commands (brew, gem, pod) will be run with sudo. You may be prompted by sudo for your password."
    CMD_PREFIX="sudo"
fi

if [[ -x `which brew` && ! -d ~/Library/Application\ Support/appledoc ]]; then
    ${CMD_PREFIX} brew install appledoc --HEAD
    ${CMD_PREFIX} ln -sf "`brew --prefix`/Cellar/appledoc/HEAD/Templates" ~/Library/Application\ Support/appledoc
fi

if [ ! -d DGSPhone.xcworkspace ]; then
    ${CMD_PREFIX} gem install bundler
    bundle install --path=~/.bundle
    bundle exec pod setup
    bundle exec pod install
else
    bundle exec pod install
fi
