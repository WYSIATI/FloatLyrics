# Float Lyrics launch film

The revised edit uses real macOS screen recordings of Float Lyrics with live
desktop-player playback. Product scenes are decoded frame by frame from those
recordings. The renderer does not recreate the app, workspace, cursor or notch
transition.

The pacing uses bold titles and product-led scenes, following the Manus/Cue
direction chosen by the owner. The music is an original synthesized score; it
does not record Spotify audio.

## Prepare footage

Put the reviewed, cropped recordings in `build/launch-footage`:

| Input | Minimum length | Content |
| --- | --- | --- |
| `floating.mp4` | 15 seconds | Actual floating lyrics over a real work/browser window |
| `island.mp4` | 12 seconds | Actual transition into compact/expanded notch mode |
| `settings.mp4` | 15 seconds | Actual nested settings and appearance interaction |

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
| 4–15 | Floating lyrics beside actual browser work |
| 15–27 | Real notch transition and playback |
| 27–39 | Real settings/appearance interaction |
| 39–42 | Work. Listen. Sing. over the recorded interface |
| 42–48 | Float Lyrics download and repository URL |

The optional captions and `x-post.txt` are editable. Nothing is posted to X by
these scripts. Original titles, graphics, code and score use the MIT license;
third-party trademarks and lyric rights remain with their owners.
