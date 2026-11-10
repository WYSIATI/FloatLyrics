import AppKit

// Finder's file icon is metadata; the matching .VolumeIcon.icns inside the DMG
// is what preserves the mounted installer logo across browser downloads.
guard CommandLine.arguments.count == 3,
      let icon = NSImage(contentsOfFile: CommandLine.arguments[1]),
      NSWorkspace.shared.setIcon(icon, forFile: CommandLine.arguments[2], options: []) else {
    fputs("Could not set the DMG's Finder icon.\n", stderr)
    exit(1)
}
