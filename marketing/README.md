# Float Lyrics launch film

The revised edit uses real macOS screen recordings of Float Lyrics with live
desktop-player playback. Product scenes are decoded frame by frame from those
recordings. The renderer does not recreate the app, workspace, cursor or notch
transition.

The pacing uses bold titles and product-led scenes, following the Manus/Cue
direction chosen by the owner. The music is an original synthesized score; it
does not record Spotify audio.

The film also teaches the first use: choosing a player, starting playback,
allowing Automation when asked, moving into/out of notch mode, and adjusting
opacity and text color. Numbered instructions and the exact menu paths are
burned into the video so the walkthrough works with sound off. The SRT is an
additional accessibility companion.

## Prepare footage

Put the reviewed, cropped recordings in `build/launch-footage`:

| Input | Minimum length | Content |
| --- | --- | --- |
| `floating.mp4` | 15 seconds | Player menu, selected Spotify source, actual playback and floating lyrics over browser work |
| `island.mp4` | 12 seconds | Move to Dynamic Island, click to expand, auto-collapse, and return to the floating window |
| `settings.mp4` | 15 seconds | Settings → Appearance, Window/Island selection, opacity slider and neutral text swatch |

Inputs must start at time zero, have upright video and contain only the intended
public work window. Keep raw recordings outside tracked files. Use only brief
permitted lyric excerpts in the public edit; microphone and system audio are
excluded. The renderer fails if recordings are missing or shorter than their
scenes. There is no sample-image fallback.

`--recording-preview` reads the real selected player's track and lyrics while
keeping recording appearance changes separate from normal listening preferences.
It does not substitute demo data.

## Rebuild

On macOS with Xcode command line tools, Python 3 and FFmpeg:

```sh
bash marketing/build.sh
# Or provide another directory of reviewed clips:
bash marketing/build.sh /absolute/path/to/footage
```

The outputs are `dist/Float-Lyrics-launch.mp4`, a poster PNG and optional SRT.
The old MP4 filename is retained as a compatibility alias. The 48-second export
uses 1920 × 1080, 30 fps, H.264 High/yuv420p, AAC stereo and a fast-start MP4.

For a title-card check without loading recordings:

```sh
swiftc -O marketing/render.swift -o build/launch-render
build/launch-render --graphics-only --frame 44 --output build/title.png
```

## Timeline

| Seconds | Scene |
| --- | --- |
| 0–4 | Float Lyrics title over real footage |
| 4–8 | 1. Choose your player: ••• → Music Player → Spotify or Apple Music |
| 8–12 | 2. Play a song in the desktop app; allow Automation if asked |
| 12–15 | Drag the lyric window; lyrics follow automatically |
| 15–20 | 3. Move to your notch: ••• → Move to Dynamic Island |
| 20–24 | Click to expand; move away to tuck it back |
| 24–27 | Expand and click the window arrow to return |
| 27–32 | 4. Make it comfortable: ••• → Settings → Appearance |
| 32–36 | Window/Island opacity; lyrics retain their contrast |
| 36–39 | Neutral text swatch; More options for custom colors |
| 39–42 | Changes save automatically; return to work |
| 42–48 | Download → Applications → Open; repository URL |

Record the real clicks in that order, without drawing a replacement cursor or
UI. If Automation was already granted, keep its instruction as a text hint;
do not reset permissions or fabricate a first-launch prompt for the film.

The optional captions and `x-post.txt` are editable. Nothing is posted to X by
these scripts. Original titles, graphics, code and score use the MIT license;
third-party trademarks and lyric rights remain with their owners.
