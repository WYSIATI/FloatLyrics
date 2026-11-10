# Float Lyrics identity

The mark is an F with its first line lifted away from the stem: a compact reference to floating lyric lines. The app icon, menu-bar template, notch and settings use the same geometry.

## Assets

- [Scalable mark](mark.svg), in graphite on a transparent background.
- [Transparent PNG mark](mark-v2.png), 512 × 512.
- [Mac app icon](app-icon-v2.png), 1024 × 1024 with transparent corners.
- [GitHub social preview](../images/social-preview-v2.png), 1280 × 640 PNG.

The vector source is implemented in `Sources/FloatLyrics/BrandMark.swift` and `scripts/make-icon.swift`. Keep their geometry and `mark.svg` aligned. The packaging script renders each icon size independently and builds the ICNS. To reproduce the brand exports:

```sh
swift scripts/make-icon.swift build/brand-refresh
cp build/brand-refresh/AppIcon.png docs/brand/app-icon-v2.png
cp build/brand-refresh/BrandMark.png docs/brand/mark-v2.png
```

## Social preview

Created with the built-in image-generation tool, following [morluto/generate-social-preview](https://github.com/morluto/generate-social-preview). The linked workflow was downloaded and its normalization helper was used. No global skill installation is required.

Direction: restrained Swiss editorial, warm paper (`#F6F5F3`), graphite (`#1F1F1F`) and silver gray. The new vector-rendered app icon and the repository's native lyric-window capture served as project references. The illustrated window uses original product-demo text; it is not a live track or an unedited screenshot.

Final copy:

- Float Lyrics
- Keep the words close.
- Live lyrics for Spotify & Apple Music.
- macOS · Floating window + notch

Window copy:

- Desktop lyrics
- Float Lyrics · Preview
- Lyrics, right on your desktop
- Follow along without switching apps

The selected card was visually checked at full size and at 640 × 320. It was then normalized to 1280 × 640 with the supplied `normalize-preview.sh`, and uploaded under the repository's **Settings → General → Social preview**. Earlier drafts remain outside tracked source.

The original generation prompt and the accepted copy revision are recorded in [social-preview-prompts.json](social-preview-prompts.json).

