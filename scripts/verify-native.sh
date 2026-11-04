#!/bin/bash
set -euo pipefail
if [[ ! -f Hitotsuzuri.xcodeproj/project.pbxproj ]]; then
  echo "リポジトリのルートで実行してください。" >&2
  exit 2
fi
stamp="$(date +%Y%m%d-%H%M%S)-$$"
result=".build/Native-$stamp.xcresult"
xcodebuild -project Hitotsuzuri.xcodeproj -scheme Hitotsuzuri -destination 'platform=macOS' -only-testing:HitotsuzuriU1Tests -only-testing:HitotsuzuriU2Tests -only-testing:HitotsuzuriU3Tests -only-testing:HitotsuzuriUITests -enableCodeCoverage YES -derivedDataPath .build/DerivedData -resultBundlePath "$result" CODE_SIGN_IDENTITY=- test
swift scripts/check-coverage.swift "$result"
