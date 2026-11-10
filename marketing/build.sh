#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build dist
footage="$PWD/build/launch-footage"
if [[ "$#" -gt 0 ]]; then footage="$1"; fi
for name in floating island settings; do
  if [[ ! -f "$footage/$name.mp4" ]]; then
    printf 'Missing reviewed real-use recording: %s/%s.mp4\n' "$footage" "$name" >&2
    exit 1
  fi
done
swiftc -O marketing/render.swift -o build/launch-render
python3 marketing/score.py
build/launch-render --footage "$footage" --output build/Float-Lyrics-launch-silent.mp4
ffmpeg -hide_banner -loglevel warning -y \
  -i build/Float-Lyrics-launch-silent.mp4 -i build/launch-score.wav \
  -map 0:v:0 -map 1:a:0 -t 48 \
  -c:v libx264 -preset medium -crf 18 -profile:v high -level:v 4.1 \
  -pix_fmt yuv420p -r 30 -g 60 -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -af 'loudnorm=I=-16:TP=-2.5:LRA=9' -c:a aac -b:a 192k -ar 48000 \
  -movflags +faststart -metadata title='Float Lyrics — Your music, a little closer' \
  -metadata comment='Real macOS screen recordings, original titles and original synthesized music. MIT source.' \
  dist/Float-Lyrics-launch.mp4
build/launch-render --footage "$footage" --frame 44 --output dist/Float-Lyrics-launch-poster.png
cp marketing/launch.srt dist/Float-Lyrics-launch.srt
# Preserve old public launch-film links.
cp dist/Float-Lyrics-launch.mp4 dist/FloatLyrics-launch.mp4
cp dist/Float-Lyrics-launch-poster.png dist/FloatLyrics-launch-poster.png
cp dist/Float-Lyrics-launch.srt dist/FloatLyrics-launch.srt
printf 'Created dist/Float-Lyrics-launch.mp4\n'
