# TIDAL Controller for Omarchy

An optional Quattro bar widget for TIDAL Rust and TIDAL web, with a compact
themed popup and conservative automatic source selection.

## Players and automatic selection

Supports the native [TIDAL Rust](https://github.com/gumuller/tidal-rs) app and
TIDAL web through your browser's local MPRIS media session. For web playback,
open TIDAL in your browser/PWA and start a track so the browser publishes its
media session. No browser extension, account access or native app is required
for web controls.

For native playback and the live FFT spectrum, install **TIDAL Rust 0.6.1+**
from [the player releases](https://github.com/gumuller/tidal-rs/releases/latest).
The command must be in the shell's PATH, or set **TIDAL Rust executable** to
its absolute path. The plugin never installs the player automatically.

The popup's source picker offers **Auto**, **TIDAL Rust** and discovered
browser sessions. Auto prefers a playing, identified TIDAL source; when two
are playing it follows the most recently observed playback start. Pausing
retains the selected source if nothing else is playing.

Auto recognizes a TIDAL identity or a TIDAL metadata/artwork URL, or a dedicated
TIDAL PWA whose browser process has only TIDAL windows. A browser process with
other windows (for example, TIDAL and WhatsApp) remains ambiguous. Song names
and the mere presence of a TIDAL tab do not qualify it for automatic selection.
Select that browser explicitly to pin the session. This choice is remembered
across shell restarts; if the browser session closes, controls become unavailable
until you select Auto or another session. It never falls through to a different
browser silently. Choosing a source does not pause or start another player.

Browser MPRIS may represent whichever media tab currently owns that browser's
media session. An explicitly pinned browser is a browser-session control, and
cannot guarantee the site if you later play something else in that same browser.
Use a dedicated TIDAL PWA/browser process for automatic identification.

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
- Right-click to show/hide the native app, or focus the selected TIDAL web window.
- Middle-click to play/pause the current track.
- When the native player is closed, **Open TIDAL Rust** starts it.
- Web controls provide metadata, play/pause, previous/next and seeking where
  supported. Browser volume is adjusted in the web app, because Chromium
  accepts MPRIS volume writes without applying them. The live FFT is native-only.
- Escape or an outside click closes the panel.
- The app's **Hide player** button or `Ctrl+H` hides its window; playback and
  its queue continue. Launching TIDAL Rust again restores the same instance.
  Closing the app window or `Ctrl+Q` exits the player.

The bar remains compact; the current track appears in its tooltip. It also
works on a vertical bar. Keyboard users can Tab through the panel buttons;
sliders support the mouse and wheel.

## Permissions and dependencies

Omarchy plugins run with your user permissions inside the shared shell. This
plugin discovers local MPRIS players directly through Quickshell and reads
Hyprland window classes/PIDs to identify dedicated TIDAL PWAs. It focuses the
specific TIDAL window with the installed Hyprland dispatcher when requested;
it does not hide the whole browser or unrelated windows.

Native commands use `env <configured-executable> control <action> [number]`
with argument arrays. No elevated permissions, installation hooks, passwords,
account tokens or stream URLs are accessed. Native status polls once per second;
browser metadata uses MPRIS and a one-second position refresh. Artwork supplied
by MPRIS may be a local file or a remote URL fetched for display. No listening
history is collected by the plugin.

Only the native source uses the app's persistent FFT subscription, and only
while the popup is open. Switching to web or closing the popup stops it. The
plugin does not capture browser or desktop audio and never shows the native
spectrum under web playback.

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
node tests/source-model.test.cjs
python scripts/validate.py
omarchy-shell shell summon gumuller.tidal '{}'
omarchy-shell shell hide gumuller.tidal
```

See [TESTING.md](TESTING.md) for runtime validation. MIT licensed. This is an
independent community project, not endorsed by TIDAL or Omarchy.
