#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/flutter-${FLUTTER_VERSION}"

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release
