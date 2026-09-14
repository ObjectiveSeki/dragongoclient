#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# All Ruby dependencies stay in this checkout; no administrator access is needed.
export GEM_HOME="$PWD/.tools/gems"
export GEM_PATH="$GEM_HOME"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
if [ ! -f "$GEM_HOME/bin/bundle" ]; then
  gem install bundler -v 2.4.22 --install-dir "$GEM_HOME" --no-document
fi
ruby "$GEM_HOME/bin/bundle" config set --local path .tools/bundle
ruby "$GEM_HOME/bin/bundle" config set --local force_ruby_platform true
ruby "$GEM_HOME/bin/bundle" install
ruby scripts/pod.rb install
python3 scripts/prepare-legacy-pods.py
python3 scripts/build-fuego.py
if [ ! -f Keys.h ]; then
  cp Keys.h.example Keys.h
fi
