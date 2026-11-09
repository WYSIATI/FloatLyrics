# Contributing

Bug reports and small pull requests are welcome. For a playback issue, include
the macOS version, selected desktop player, track title/artist, and whether the
problem affects timing, matching or display. Do not attach account details,
listening history or complete lyric cache files.

Open `Package.swift` in Xcode 26 or newer, or use:

```sh
swift test
ARCHITECTURE=native bash scripts/build-app.sh
```

Keep the primary interface quiet: song, lyrics and one menu. Put secondary
controls in Settings and advanced choices in nested pages. Retain native glass,
neutral colors, keyboard access and Reduce Motion support. A playback or
matching fix should include a regression test; a visual change should include
screenshots with original sample lyrics (`--demo`).

Before a release, run `scripts/package-dmg.sh` and `scripts/verify-dmg.sh`.
See [release instructions](docs/RELEASING.md). Keep commits focused and use
clear imperative subjects. Do not add coauthor trailers.
