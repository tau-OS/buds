<img align="left" style="vertical-align: middle" width="120" height="120" src="data/icons/co.tauos.Buds.svg">

# Buds

A Contacts App

###

[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

## 🛠️ Dependencies

You'll need the following dependencies:

> *Note*: This dependency list is the names searched for by `pkg-config`. Depending on your distribution, you may need to install other packages (for example, `gtk4-devel` on Fedora)

- `meson`
- `valac`
- `gtk4`
- `folks`
- `libhelium-1`

## 🏗️ Building

Simply clone this repo, then run `meson build` to configure the build environment. Change to the build directory and run `ninja test` to build and run automated tests.

```bash
$ meson build --prefix=/usr
$ cd build
$ ninja test
```

Or alternatively, run on Builder or VSCode as a flatpak manifest is included.

## 📦 Installing

To install, use `ninja install`, then execute with `buds`.

```bash
$ sudo ninja install
$ co.tauos.Buds
```
