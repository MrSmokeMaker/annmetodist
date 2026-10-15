#!/usr/bin/env bash
set -e

echo "=== Preparing Flutter SDK on Netlify ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH="$PWD/flutter/bin:$PATH"

echo "=== Flutter Doctor ==="
flutter doctor -v

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter Web release ==="
flutter build web --release --no-web-resources-cdn

echo "=== Ensuring Netlify _redirects and _headers are in build/web ==="
cp web/_redirects build/web/_redirects 2>/dev/null || true
cp web/_headers build/web/_headers 2>/dev/null || true

echo "=== Build Complete! Ready for Netlify publish ==="
