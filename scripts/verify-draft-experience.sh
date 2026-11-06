#!/bin/bash
set -euo pipefail
if [[ ! -f Hitotsuzuri.xcodeproj/project.pbxproj ]]; then
  echo "リポジトリのルートで実行してください。" >&2
  exit 2
fi
python3 scripts/native-test-runner.py draft "$@"
