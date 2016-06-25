# xcode-register

A small tool that registers all your installed Xcode plugins.

## Introduction

`xcode-register` is created to automate the repeated labor of adding the Xcode
plugin identifier `DVTPlugInCompatibilityUUID` into all my plugins' `Info.plist`
files. Previously I used a shell script but that script is not reentrant. This
small Objective-C program does exactly that, however it is reentrant and can be
fairly robust.

## Installation

Copy and paste the following shell script into a Terminal windowto install or
update `xcode-register`:

## Usage

The simplest way of using `xcode-register` is to let it register all existing
plugins of the current user to the default installation of Xcode, by running:

    xcode-register

If you need to register the plugins to some other versions of Xcode, for example
a beta version installed at `/Applications/Xcode-beta.app`, run this:

    xcode-register --xcode /Applications/Xcode-beta.app

Execute this for complete instructions of `xcode-register`:

    xcode-register --help

## License

## License

`xcode-build` is covered in [the three-clause BSD license](LICENSE.md).

## Contact information

DreamCity by Max Chan

* Email: &lt;<max@maxchan.info>&gt;
* Website: <https://en.maxchan.info>
* Twitter: [@maxtch](https://twitter.com/maxtch)
