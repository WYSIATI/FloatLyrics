# Float Lyrics privacy policy

Updated November 17, 2026.

## Playback on your Mac

Float Lyrics uses macOS Automation to read the current song in the desktop player you select. It reads the title, artist, album, duration, track identifier, playback state and position. The position and state determine which lyric line to show. The identifier helps match locally cached lyrics to the recording.

Float Lyrics works without an account. The app has no advertising or analytics SDK and does not record audio.

## Lyric lookups

When a result is missing from your local cache, or when you choose **Refresh lyrics**, the app contacts LRCLIB over HTTPS. A lookup includes the track title and artist. It also includes the album when available and the rounded duration when supported. A fallback search uses only the title and artist. The request identifies the Float Lyrics app, and the network connection exposes your IP address to the service. Your player account, track identifier, playback position and shortcut preferences stay out of these requests.

Your Mac connects directly to LRCLIB. Float Lyrics does not run a server that receives these queries. LRCLIB operates its own service and controls its handling of requests. Its API documentation describes IP-based rate limiting. [LRCLIB service documentation](https://lrclib.net/docs)

## Local storage and your choices

The app caches matched lyrics on your Mac so it can reuse them. It saves preferences such as the selected player, appearance, window position and show/hide shortcut in macOS preferences. The app applies no fixed expiration to its lyric files. You can quit Float Lyrics and remove the lyric cache in Finder using **Go → Go to Folder**. For the Mac App Store version, enter this path.

    ~/Library/Containers/app.floatlyrics.desktop/Data/Library/Caches/app.floatlyrics.desktop/lyrics

For a copy installed from the project's DMG, use this path.

    ~/Library/Caches/app.floatlyrics.desktop/lyrics

To stop reading a player's playback information, revoke its permission in **System Settings → Privacy & Security → Automation → Float Lyrics**. Quitting Float Lyrics stops new lyric lookups. Hiding its window lets it continue following the song.

## External links and updates

Help and privacy links may open GitHub in your browser. In the direct-download edition, **Check for Updates…** contacts GitHub for the latest public release. That request sends no playback data. Updates for the Mac App Store edition are handled by the App Store. [GitHub privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)

## Contact

For questions about this policy or deleting local data, contact the maintainers through the project's support page. Keep personal information out of public issues. [Float Lyrics support](docs/app-store/support.md)
