# TIDAL Rust Controller for Omarchy

An optional Quattro bar widget for [TIDAL Rust](https://github.com/gumuller/tidal-rs).
Open a compact, themed music controller without keeping the player's window
on screen. Playback remains in the native Rust/GTK4 application.

## Install the player first

Requires **TIDAL Rust 0.6.1 or newer**, a TIDAL account, and a subscription that
permits playback. Install the Arch package or native binary bundle from the
[player releases](https://github.com/gumuller/tidal-rs/releases/latest).
The installed `tidal-rs` command must be in the Omarchy shell's PATH. If it is
elsewhere, set the widget's **TIDAL Rust executable** setting to its absolute path.

The player is independent of Omarchy and remains usable when this plugin is
removed. This plugin deliberately does not install software or run an installer
on your behalf. If the dependency is missing, the panel explains what is needed.

## Install the optional plugin

```sh
omarchy plugin add https://github.com/gumuller/omarchy-tidal.git --enable
```

Review the prompt and enable the widget. It appears in the right bar section;
move it with:

```sh
omarchy bar move gumuller.tidal --section right
```

Requires Omarchy Quattro (tested on Omarchy 4.0.4). Uses the shell's existing
`BarWidget`, `KeyboardPanel`, buttons, sliders and theme tokens; it does not
start another Quickshell process or replace your bar.

## Use

- Left-click **TIDAL** for artwork, track/artist, actual playback quality,
  play/pause, next/previous, seeking, volume, a live 64-band spectrum and **Show/Hide player**.
- Right-click the bar widget to show/hide the app directly.
- Middle-click to play/pause the current track.
- When the player is closed, **Open TIDAL Rust** starts it.
- Escape or an outside click closes the panel.
- The app's **Hide player** button or `Ctrl+H` hides its window; playback and
  its queue continue. Launching TIDAL Rust again restores the same instance.
  Closing the app window or `Ctrl+Q` exits the player.

The bar remains compact; the current track appears in its tooltip. It also
works on a vertical bar. Keyboard users can Tab through the panel buttons;
sliders support the mouse and wheel.

## Permissions and dependencies

Omarchy plugins run with your user permissions inside the shared shell. This
plugin launches only `env <configured-executable> control <action> [number]`,
using argument arrays rather than an interpolated shell command. By default
that is `tidal-rs`. No elevated permissions, installation hooks, network requests, account tokens,
passwords, stream URLs or mpv sockets are accessed by the plugin. It receives
public playback metadata and cached artwork paths through the player's session
D-Bus control interface. Status polls once per second while running, otherwise
every five seconds. While the popup is open, one persistent `tidal-rs control spectrum`
process subscribes to FFT frames over D-Bus. It stops when the popup closes.
The spectrum reuses the app's audio capture and animates bars and peak markers
at 60 fps; the plugin does not capture audio itself. No playback history is
collected by the plugin.

The **executable** setting chooses code to run under your account, so use only
your installed player. The app's system dependencies (GTK4, mpv, libpulse and
xdg-utils) are documented and managed by its own package. The widget uses the
Nerd Font shipped with Omarchy for transport glyphs.

## Update or remove

```sh
omarchy plugin update gumuller.tidal
omarchy plugin disable gumuller.tidal
omarchy plugin enable gumuller.tidal
omarchy plugin remove gumuller.tidal
```

Removal only removes this plugin and its bar entry. It leaves your player,
account, playback settings and listening history alone. There are no services,
keybindings or autostart files to clean up.

## Development and validation

```sh
python scripts/validate.py
omarchy-shell shell summon gumuller.tidal '{}'
omarchy-shell shell hide gumuller.tidal
```

See [TESTING.md](TESTING.md) for runtime validation. MIT licensed. This is an
independent community project, not endorsed by TIDAL or Omarchy.
