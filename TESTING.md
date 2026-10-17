# Validation

Target: Omarchy 4.0.4 / Quattro, with TIDAL Rust 0.6.0.

Static checks:

```sh
python scripts/validate.py
```

Runtime acceptance checks, inside the existing Omarchy shell:

1. Enable `gumuller.tidal`; verify the bar button and panel render with the current theme.
2. Summon and hide through shell IPC. Reopen, dismiss with Escape and outside click.
3. Open the installed player from the panel when closed.
4. Start a track in the app; check artwork, title, artist, quality and progress.
5. Hide/show repeatedly; the same process and playback continue.
6. Pause/resume, seek, change volume and move next/previous from the panel.
7. Hide the app while playing; confirm metadata keeps advancing and controls work.
8. Disable/re-enable the plugin; playback continues and the widget returns.
9. Remove the plugin; the player still runs and no unrelated bar entries change.
10. Test with a missing executable: explanatory message, disabled controls, no auto-install.

The player's own real GTK/AT-SPI E2E suite verifies the D-Bus control interface,
including hidden-state progress, pause/resume, seek, volume and restoration of
the same process. No user credentials are included in this repository.

## Verified for v1.0.0 on 17 October 2026

Manifest validation and qmllint completed using the installed shell imports.
The live Omarchy shell rendered the themed popup and its missing-dependency
message. Keyboard activation of the panel's Open button launched the installed
0.6.0 player. Play/Pause, Next, Previous and Show were exercised through the
panel while the app was hidden, preserving the process and queue. The player's
28-check E2E suite separately validated hidden status updates, seek and volume.

Panel Escape dismissal, disable/re-enable and removal were also exercised in the
live shell while muted audio advanced. Playback continued, and removing the
plugin restored the exact original shell configuration. Tests restored the
original player volume and left playback paused.
