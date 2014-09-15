#!/bin/sh
dart test/tests.dart
pub build test/

which content_shell
if [[ $? -ne 0 ]]; then
  $DART_SDK/../chromium/download_contentshell.sh
  unzip content_shell-linux-x64-release.zip

  cs_path=$(ls -d drt-*)
  PATH=$cs_path:$PATH
fi

results=$(content_shell --dump-render-tree test/client_test.html 2>&1)
echo -e "$results"

if [[ "$results" == *"FAIL"* ]]
then
  exit 1
fi