#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build dist
swiftc -O marketing/render.swift -o build/launch-render
python3 marketing/score.py
build/launch-render --output build/FloatLyrics-launch-silent.mp4
ffmpeg -hide_banner -loglevel warning -y \
  -i build/FloatLyrics-launch-silent.mp4 -i build/launch-score.wav \
  -map 0:v:0 -map 1:a:0 -t 48 \
  -c:v libx264 -preset medium -crf 18 -profile:v high -level:v 4.1 \
  -pix_fmt yuv420p -r 30 -g 60 -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -af 'loudnorm=I=-16:TP=-2.5:LRA=9' -c:a aac -b:a 192k -ar 48000 \
  -movflags +faststart -metadata title='FloatLyrics — Your music, a little closer' \
  -metadata comment='Native product captures, original motion graphics and original synthesized music. MIT source.' \
  dist/FloatLyrics-launch.mp4
build/launch-render --frame 12 --output dist/FloatLyrics-launch-poster.png
cp marketing/launch.srt dist/FloatLyrics-launch.srt
printf 'Created dist/FloatLyrics-launch.mp4\n'
