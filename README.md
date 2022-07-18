<img align="left" style="vertical-align: middle" width="120" height="120" src="data/icons/co.tauos.Buds.svg">

# Buds

A Contacts App

###

[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

## 🛠️ Dependencies

You'll need the following dependencies:

> _Note_: This dependency list is the names searched for by `pkg-config`. Depending on your distribution, you may need to install other packages (for example, `gtk4-devel` on Fedora)

- `meson`
- `ninja`
- `flatpak`
- `flatpak-builder`
- `rustc`
- `gtk4`
- `libhelium-1`


## 🏗️ Building

Run the commands below.

> _Note_: These commands are just for demonstration purposes. Normally this would be handled by your IDE, such as GNOME Builder or VS Code with the Flatpak extension.

```
$ flatpak install org.gnome.Sdk//42 org.freedesktop.Sdk.Extension.rust-stable//21.08 org.gnome.Platform//42
$ flatpak-builder --user flatpak_app build-aux/co.tauos.Buds.Devel.json
```

## 📦 Running

Run the command below.

> _Note_: These commands are just for demonstration purposes. Normally this would be handled by your IDE, such as GNOME Builder or VS Code with the Flatpak extension.

```
$ flatpak-builder --run flatpak_app build-aux/co.tauos.Buds.Devel.json buds
```
