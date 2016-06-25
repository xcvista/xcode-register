#!/bin/bash

REMOTE_PATH=https://github.com/xcvista/xcode-register/archive/master.tar.gz
LOCAL_PATH=xcode-register-master

curl -L $REMOTE_PATH | tar xz
pushd $LOCAL_PATH
xcodebuild -alltargets build
sudo cp build/Release/xcode-register /usr/local/bin
popd
rm -r $LOCAL_PATH
