# App screenshots

Native, window-only captures of Float Lyrics 1.4.2 on macOS 26.5.2, taken on
2026-11-10.
These show the actual SwiftUI/AppKit interface with the app's original `--demo`
text. They contain no third-party song lyrics or surrounding desktop content.

The additional 1.5.1 shortcut-settings image is rendered directly from the real
SwiftUI/AppKit view by `SettingsRecorderTests`, using isolated demo preferences
with lyric opacity at 15%. It verifies that Settings itself remains solid; it
is a view render, not an on-screen capture or a mockup.

| File | Pixels | View |
| --- | --- | --- |
| [floating-window.png](floating-window.png) | 800 × 448 | Floating lyric window |
| [island-compact.png](island-compact.png) | 920 × 152 | Compact island at the top edge |
| [island-expanded.png](island-expanded.png) | 920 × 292 | Expanded island and its controls |
| [settings.png](settings.png) | 700 × 600 | Settings index |
| [appearance.png](appearance.png) | 700 × 700 | Window appearance controls |
| [settings-shortcuts.png](settings-shortcuts.png) | 700 × 1080 | 1.5.1 solid Settings and shortcut instructions (view render) |

PNG exports retain the display's native 2× dimensions. The capture tool returns
JPEG images; these were decoded and saved as PNGs without further lossy
compression. The compact island's unused lower capture area was cropped; the
interface was not redrawn, enlarged or retouched. Island lyrics use White for
clear contrast.
Window appearance uses the default Glass material, 70% opacity and Automatic
lyric color. Glass backgrounds can vary with the desktop behind the app.

## Refresh

1. Build the current app with `ARCHITECTURE=native bash scripts/build-app.sh`.
2. Launch a demo instance, keeping normal listening preferences separate:

   ```sh
   open -n "build/Float Lyrics.app" --args --demo --demo-position 15
   ```

3. Capture only the app window at native resolution, with the pointer outside
   the captured window. The demo advances through its sample lines; capture
   early to include a next line, or later for the final line shown here.
4. Use **••• → Move to Dynamic Island** for the compact view, then click it to
   expand. Capture the expanded view before it automatically collapses.
5. Open **⌘,** for the Settings index and choose **Appearance** for the controls.
   Appearance changes in `--demo` use preview preferences, not listening
   preferences. The capture session used a separate local app bundle so the
   normal listening instance could keep running.
6. Export lossless PNGs, trim unused space without cutting off controls or the
   island's screen-edge shoulders, and inspect every image at README size.
   Keep raw captures and temporary builds under the ignored `build/` directory.

The main [README](../../README.md#screenshots) links to the full-resolution
files. Keep its image descriptions and this table current when replacing them.

To regenerate the 1.5.1 view render:

```sh
FLOATLYRICS_SETTINGS_SNAPSHOT_DIR="$PWD/build/settings-snapshots" \
swift test --filter SettingsRecorderTests.testSettingsSurfaceStaysOpaqueAtMinimumLyricOpacity
```

Inspect the PNG before copying it into this directory. The test also checks
that the rendered background's alpha stays above 99% at the minimum lyric opacity.
