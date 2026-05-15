# Android Export

This document describes how to export the Android MVP build of Reptile Tycoon from Godot.

## Current Project Values

- Godot project feature/version marker: Godot 4.6 / Godot 4.x.
- App name: Reptile Tycoon.
- Package name: `com.makssnake.reptiletycoon`.
- Version name: `0.1.0-debug`.
- Version code: `1`.
- Orientation: portrait.
- Target screen: mobile portrait, 9:16 with support for taller Android screens.
- Main scene: `res://scenes/main/Main.tscn`.
- Save path: `user://save_game.json`.
- Debug APK filename: `reptile-tycoon-debug.apk`.
- Google Play upload format later: AAB.

## Required Tools

- Godot 4.x compatible with this project.
- Matching Android export templates installed in Godot.
- Android SDK installed locally.
- Android build-tools installed, including `adb`, `apksigner`, and current build-tools package.
- Java/JDK installed and configured for the Godot Android exporter.
- Debug keystore for local debug APK testing.
- Release keystore for production or Play testing upload.

Debug and release signing are different. Debug APKs can use the local debug keystore. Production uploads must use a properly managed release signing setup. Do not generate, commit, or share private signing keys in this repository.

## Project Settings

Verify these in Godot before export:

1. Open `Project > Project Settings`.
2. Confirm `Application > Config > Name` is `Reptile Tycoon`.
3. Confirm `Application > Config > Version` is `0.1.0-debug`.
4. Confirm `Application > Run > Main Scene` is `res://scenes/main/Main.tscn`.
5. Confirm `Display > Window > Handheld > Orientation` is portrait.
6. Confirm the viewport remains mobile portrait friendly.
7. Confirm save code uses `user://save_game.json`, not a raw relative path.

## Android Editor Settings

In Godot, open `Editor > Editor Settings > Export > Android` and configure:

1. Android SDK path.
2. Java/JDK path.
3. Debug keystore path and password if required by your local setup.
4. Build-tools path if Godot does not auto-detect it.

Do not hardcode user-specific SDK or JDK paths into project files.

## Debug APK Export

Use the existing Android export preset:

1. Open Godot.
2. Open `Project > Export`.
3. Select `ReptileTycoon Android Debug`.
4. Confirm platform is `Android`.
5. Confirm package name is `com.makssnake.reptiletycoon`.
6. Confirm version code is `1`.
7. Confirm version name is `0.1.0-debug`.
8. Keep export format as APK for debug testing.
9. Click `Export Project`.
10. Export as `reptile-tycoon-debug.apk`.

Current preset path is:

```text
../RTI_app/reptile-tycoon-debug.apk
```

## Release AAB Preparation

Google Play upload should use an Android App Bundle (`.aab`) for release/testing tracks.

Before uploading a release or closed-test build:

1. Create or select a release Android export preset.
2. Set export format to AAB.
3. Increment version code for every upload.
4. Use a release signing setup or Play App Signing as appropriate.
5. Keep private keystores and passwords outside the repository.
6. Export and install/test a matching debug APK before uploading AAB.

This repo should not contain private signing keys, keystore passwords, or Play Console credentials.

## Android Device Test

After exporting the APK:

1. Connect an Android phone with USB debugging enabled.
2. Install the build:

```text
adb install -r path/to/reptile-tycoon-debug.apk
```

3. Launch Reptile Tycoon.
4. Confirm the welcome screen appears.
5. Confirm portrait orientation stays locked.
6. Tap through the main menu and biome map.
7. Test touch UI on top bar, bottom menu, shop, quests, animals, upgrades, and settings.
8. Buy a habitat.
9. Buy a reptile in the shop.
10. Assign and unassign the reptile.
11. Perform care actions.
12. Close and reopen the app to test save/load.
13. Force close the app, wait, then reopen to test offline progress.
14. Minimize and resume to check pause/resume stability.

## Troubleshooting

### Missing Export Templates

Install the exact Android export templates for your Godot version from `Editor > Manage Export Templates`.

### Missing Android SDK Path

Set the SDK path in `Editor Settings > Export > Android`. Avoid committing machine-local paths.

### Missing JDK Path

Install a compatible JDK and set its path in Godot editor settings.

### `adb` Not Found

Install Android platform-tools and ensure `adb` is available from the Android SDK path.

### `apksigner` or Build-tools Not Found

Install Android build-tools through Android SDK Manager. Verify Godot points at the SDK containing build-tools.

### Case-sensitive Asset Paths on Android

Android export is case-sensitive. Check that every `res://` path exactly matches the filename casing on disk. Core startup paths currently checked include welcome screen, Green Meadow background, top bar, bottom menu, habitat visuals, reptile management UI, rarity icons, menu icons, shop/quest/achievement UI, and reptile portraits.

Known non-core gap: `data/biomes.json` references `res://assets/art/biomes/dry_prairie.png`, but Biom 2 is not currently a playable core scene and no final dry prairie biome background exists yet.

### `.png.png` Paths

Core data/code paths should not contain duplicated `.png.png` extensions. `AssetPaths.gd` also warns and normalizes this mistake at runtime.

### Save File Path Mistakes

Use:

```text
user://save_game.json
```

Do not use:

```text
save_game.json
res://save_game.json
```

Raw relative paths can fail or write to unexpected locations on Android.
