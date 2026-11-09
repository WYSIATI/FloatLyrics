# FloatLyrics launch film

A 48-second, 1920 × 1080, 30 fps launch film for X. Kinetic headlines on a
neutral dotted canvas, native interface scenes, a camera-integrated island
transition, and an original 120 BPM electronic score. It reads with sound muted.

The Manus/Cue launch direction was a pacing/motion reference, confirmed by the
project owner. The product, layouts, graphics, copy and score are original.
No Cue characters, launch footage, soundtrack, Spotify audio or commercial lyrics
are included. See [the source reference](https://manus.im/blog/introducing-video-editor).

## Rebuild

On macOS with Xcode command line tools, Python 3 and FFmpeg installed:

```sh
bash marketing/build.sh
```

Outputs: `dist/FloatLyrics-launch.mp4`, a poster PNG and optional SRT captions.
The movie uses H.264 High / yuv420p, AAC stereo, fast-start MP4, and a 48-second
duration, comfortably inside X's standard 140-second / 512 MB allowance.
See [X's current upload guidance](https://help.x.com/en/using-x/x-videos).

`render.swift` is the editable scene timeline and graphics engine. It also accepts
`--frame 25 --output build/frame.png` for a still, or `--draft` for a 960 × 540,
15 fps motion preview. `score.py` synthesizes every sound without external
samples. The mix targets -16 LUFS and -2.5 dBTP before AAC encoding, leaving room
for encoding overshoot. Encoded loudness and true peak are checked separately.

## Product evidence

Images in `assets` were captured through the running native app using original
`--demo` lyrics and isolated preview preferences. A fictional Notes workspace
provides context; no personal documents or listening history appear. The movie
composition removes the capture pointer from the island's metadata strip and
keeps its native lyric body. On-screen interface sizes are enlarged for clarity.

The downloadable app remains deliberately simple: song, current lyric, next
line and one menu. The film makes no claim of notarization, perfect lyric
coverage, browser-player support or an Apple/Spotify affiliation.

## Timeline

| Seconds | Scene |
| --- | --- |
| 0–3 | Know the song: notes and kinetic headline |
| 3–6 | Lose the next line: the problem |
| 6–9 | FloatLyrics name and native app icon |
| 9–16 | Actual lyric window above a fictional workspace |
| 16–21 | Spotify / Apple Music and lyric window |
| 21–29 | Actual compact / expanded notch states, then collapse |
| 29–36 | Simple Settings and the softer native glass card |
| 36–41 | Work in flow. Sing along. |
| 41–48 | Free/open-source Mac download and repository URL |

`x-post.txt` is a launch-post draft. Nothing is posted to X by these scripts.
The source, original graphics and score are provided under the repository's MIT
license. System fonts are rasterized using macOS; no font files are redistributed.
