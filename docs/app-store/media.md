# Mac App Store media

Each set contains three opaque 2880 × 1800 sRGB screenshots, in the order below. Both sets show the English app controls and original demo lyrics. The owner approved the English set on November 17, 2026 for international Mac App Store distribution. The Chinese set is for review only. Apple's language-based localization can show Simplified Chinese on the U.S. storefront. [Storefront language table](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)

| Feature | English (approved for international distribution) | Simplified Chinese (review only) |
| --- | --- | --- |
| Floating lyrics over the photo beside the field notes | [01-floating-window.png](screenshots/en-US/01-floating-window.png) | [01-floating-window.png](screenshots/zh-Hans/01-floating-window.png) |
| Compact and expanded notch views | [02-notch.png](screenshots/en-US/02-notch.png) | [02-notch.png](screenshots/zh-Hans/02-notch.png) |
| Dark appearance, 85% opacity and white lyrics | [03-appearance.png](screenshots/en-US/03-appearance.png) | [03-appearance.png](screenshots/zh-Hans/03-appearance.png) |

The [English preview](preview/float-lyrics-mac-preview.mp4) is approved for the international listing. The [Simplified Chinese preview](preview/float-lyrics-mac-preview-zh-Hans.mp4) is for owner review only. The playback demonstration seeks from 0:05 to 0:27 in an original local track, lets playback continue, then seeks back to 0:08. The native lyric window follows both jumps. The labeled demo timeline shows the position from the local AVPlayer capture. See the [capture and encoding notes](preview/README.md).

## Image sources

The floating and appearance panels were rendered at 4× using the app’s own SwiftUI/AppKit views and isolated demo data. The first screenshot shows a 1060 × 455 pt native macOS document, *Coastal field notes*, with an original passage on the left and a generated coastal photograph on the right. The 400 × 224 pt lyric window uses a 32% background opacity and sits entirely over the photograph. The notch comparison uses the [compact](../screenshots/island-compact.png) and [expanded](../screenshots/island-expanded.png) on-screen captures, cropped to their silhouettes. The backdrops and headings were composed around the native interface. All lyric lines in the media come from the project’s original demo.

The layouts take cues from the window comparisons in Dark Noise and the filled-in desktop windows in Things 3. All product imagery in these exports comes from Float Lyrics or the original sample document. [Dark Noise Mac screenshots](https://darknoise.app/press.html) · [Things 3 for Mac](https://culturedcode.com/things/features/)

See Apple’s [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [app preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/) for upload dimensions and formats.
