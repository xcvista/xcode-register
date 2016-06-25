#!/bin/bash

REMOTE_PATH=https://github.com/xcvista/xcode-register/archive/master.tar.gz
LOCAL_PATH=xcode-register-master

curl -L $REMOTE_PATH | tar xz
pushd LOCAL_PATH
xcodebuild -alltarget build
sudo xcodebuild -alltarget install
popd
rm -r LOCAL_PATH
