#!/bin/bash

# run server tests
results=$(dart test/server/server_test.dart 2>&1)
echo -e "$results"

if [[ "$results" == *"FAIL"* ]]
then
  exit 1
fi

#compile to javascript
results=$(pub build test/ 2>&1)
echo "$results"
if [[ "$results" == *"Build failed"* ]]
then
  exit 1
fi

#run client tests
which content_shell
if [[ $? -ne 0 ]]; then
  $DART_SDK/../chromium/download_contentshell.sh
  unzip content_shell-linux-x64-release.zip

  cs_path=$(ls -d drt-*)
  PATH=$cs_path:$PATH
fi

results=$(content_shell --dump-render-tree build/test/client_test.html 2>&1)
echo -e "$results"

if [[ "$results" == *"FAIL"* ]]
then
  exit 1
fi