# homebrew-emacs

This is a 3<sup>rd</sup> party tap for [Homebrew](https://brew.sh/). It provides a formula for `emacs` which includes options for enabling additional features.

## Installation and usage

In order to use this tap, you need to install Homebrew.

Then, to run a default installation, run:

```bash
brew tap miles170/emacs
brew install miles170/emacs/emacs --with-native-comp --with-json
```

### Options

| Option               | Description                   |
|----------------------|-------------------------------|
| =--with-json=        | build with fast JSON          |
| =--with-native-comp= | build with native compilation |

## Issues

To report issues, please [file an issue on GitHub](https://github.com/miles170/homebrew-emacs/issues). Please include the full command line you have tested and the full terminal output you got with. Please note that we will only be able to help with issues that are exclusive to this tap and for OS which are officially supported.

If the problem is reproducible with the `homebrew-core` version of `emacs`, please file it [on their tracker](https://github.com/Homebrew/homebrew-core/).
