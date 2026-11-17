#!/usr/bin/env python3
"""Prepare the verified Store build for Xcode Organizer or archive it with a team."""

import argparse
import datetime
import plistlib
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "Resources/AppStoreArchive"
ENTITLEMENTS = ROOT / "Resources/FloatLyrics-AppStore.entitlements"


def uuids(path):
    output = subprocess.check_output(["xcrun", "dwarfdump", "--uuid", path], text=True)
    return dict(re.findall(r"^UUID: ([\dA-Fa-f-]+) \(([^)]+)\)", output, re.MULTILINE))


def verify(app, symbols, team_id=None):
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    binary_ids = uuids(executable)
    if not binary_ids or uuids(symbols) != binary_ids:
        raise SystemExit("The symbols do not match the Store app. Rebuild with bash scripts/build-app.sh --app-store.")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", "--all-architectures", app], check=True)
    expected = plistlib.loads(ENTITLEMENTS.read_bytes())
    for arch in binary_ids.values():
        data = subprocess.check_output(["codesign", "-d", "--arch", arch, "--entitlements", "-", "--xml", app])
        entitlements = plistlib.loads(data)
        if any(entitlements.get(key) != value for key, value in expected.items()):
            raise SystemExit(f"The {arch} app signature is missing the expected Store entitlements.")
        if team_id:
            details = subprocess.run(["codesign", "-dv", "--arch", arch, app], check=True, capture_output=True, text=True)
            if f"TeamIdentifier={team_id}" not in details.stderr.splitlines():
                raise SystemExit(f"The {arch} app was not signed by the requested Apple Developer team.")
    return info, sorted(binary_ids.values())


def prepare_project(directory, app, symbols, info, archs, team_id):
    project = directory / "FloatLyricsStore.xcodeproj"
    schemes = project / "xcshareddata/xcschemes"
    schemes.mkdir(parents=True)
    shutil.copy2(TEMPLATE / "project.pbxproj", project)
    shutil.copy2(TEMPLATE / "Float Lyrics.xcscheme", schemes)
    inputs = directory / "input"
    inputs.mkdir()
    contents = app / "Contents"
    shutil.copy2(contents / "Info.plist", inputs)
    shutil.copy2(ENTITLEMENTS, inputs / "Store.entitlements")
    shutil.copy2(TEMPLATE / "stage-product.sh", inputs)
    subprocess.run(["ditto", contents / "MacOS" / info["CFBundleExecutable"], inputs / "executable"], check=True)
    subprocess.run(["ditto", contents / "Resources", inputs / "Resources"], check=True)
    subprocess.run(["ditto", symbols, inputs / "Symbols.dSYM"], check=True)
    settings = {
        "DEVELOPMENT_TEAM": team_id,
        "PRODUCT_BUNDLE_IDENTIFIER": info["CFBundleIdentifier"],
        "EXECUTABLE_NAME": info["CFBundleExecutable"],
        "MARKETING_VERSION": info["CFBundleShortVersionString"],
        "CURRENT_PROJECT_VERSION": info["CFBundleVersion"],
        "MACOSX_DEPLOYMENT_TARGET": info["LSMinimumSystemVersion"],
        "ARCHS": " ".join(archs),
    }
    (directory / "Release.xcconfig").write_text("".join(f"{key} = {value}\n" for key, value in settings.items()))
    return project


def local_archive(bundle, app, symbols, info, archs):
    name = info["CFBundleName"]
    app_path = Path("Applications") / app.name
    product = bundle / "Products" / app_path
    product.parent.mkdir(parents=True)
    (bundle / "dSYMs").mkdir()
    subprocess.run(["ditto", app, product], check=True)
    subprocess.run(["ditto", symbols, bundle / "dSYMs" / (app.name + ".dSYM")], check=True)
    verify(product, bundle / "dSYMs" / (app.name + ".dSYM"))
    metadata = {
        "ArchiveVersion": 2,
        "CreationDate": datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None),
        "Name": name,
        "SchemeName": name,
        "ApplicationProperties": {
            "ApplicationPath": str(app_path),
            "Architectures": archs,
            "CFBundleIdentifier": info["CFBundleIdentifier"],
            "CFBundleShortVersionString": info["CFBundleShortVersionString"],
            "CFBundleVersion": info["CFBundleVersion"],
            "IconPaths": [str(app_path / "Contents/Resources" / (info["CFBundleIconFile"] + ".icns"))],
        },
    }
    (bundle / "Info.plist").write_bytes(plistlib.dumps(metadata))


def archive(output_dir, team_id=None, project_only=False):
    if team_id and not re.fullmatch(r"[A-Z0-9]{10}", team_id):
        raise SystemExit("Use the seller's ten-character Apple Developer team ID.")
    if project_only and not team_id:
        raise SystemExit("--prepare-project requires --team-id.")
    app = ROOT / "build/app-store/Float Lyrics.app"
    symbols = ROOT / "build/swiftpm-app-store/apple/Products/Release/FloatLyrics.dSYM"
    if not app.is_dir() or not symbols.is_dir():
        raise SystemExit("Build the release app and symbols with bash scripts/build-app.sh --app-store.")
    info, archs = verify(app, symbols)
    basename = f"{info['CFBundleName'].replace(' ', '-')}-{info['CFBundleShortVersionString']}-{info['CFBundleVersion']}"
    filename = f"{basename}-{team_id}-signing" if project_only else f"{basename}.xcarchive"
    output_dir = output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    destination = output_dir / filename
    if destination.exists():
        raise SystemExit(f"Output already exists: {destination}. Use --output-dir to keep another copy.")
    with tempfile.TemporaryDirectory(dir=output_dir) as tmp:
        work = Path(tmp)
        if team_id:
            project_dir = work / "signing"
            project = prepare_project(project_dir, app, symbols, info, archs, team_id)
            if project_only:
                project_dir.rename(destination)
            else:
                bundle = work / filename
                subprocess.run([
                    "xcodebuild", "-project", project, "-scheme", "Float Lyrics", "-configuration", "Release",
                    "-destination", "generic/platform=macOS", "-derivedDataPath", work / "DerivedData",
                    "-archivePath", bundle, "-allowProvisioningUpdates", "archive",
                ], check=True)
                properties = plistlib.loads((bundle / "Info.plist").read_bytes())["ApplicationProperties"]
                if properties.get("Team") != team_id or properties.get("CFBundleIdentifier") != info["CFBundleIdentifier"]:
                    raise SystemExit("Xcode did not associate the archive with the expected team and bundle identifier.")
                product = bundle / "Products" / properties["ApplicationPath"]
                verify(product, bundle / "dSYMs" / (product.name + ".dSYM"), team_id)
                bundle.rename(destination)
            options = work / f"{basename}-{team_id}-ExportOptions.plist"
            options.write_bytes(plistlib.dumps({
                "destination": "export",
                "method": "app-store-connect",
                "signingStyle": "automatic",
                "manageAppVersionAndBuildNumber": False,
                "teamID": team_id,
            }))
            options.replace(output_dir / options.name)
        else:
            bundle = work / filename
            local_archive(bundle, app, symbols, info, archs)
            bundle.rename(destination)
    print(destination / "FloatLyricsStore.xcodeproj" if project_only else destination)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "dist/app-store")
    parser.add_argument("--team-id", help="Apple Developer team to sign the archive and generate export options for")
    parser.add_argument("--prepare-project", action="store_true", help="prepare a self-contained native project for Product → Archive in Xcode")
    args = parser.parse_args()
    archive(args.output_dir, args.team_id, args.prepare_project)
