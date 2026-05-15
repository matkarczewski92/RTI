# Release Checklist

Internal checklist for Reptile Tycoon Android testing and Google Play preparation.

## Build

- [ ] Android export templates installed.
- [ ] Android SDK configured in Godot.
- [ ] JDK configured in Godot.
- [ ] Debug APK exports as `reptile-tycoon-debug.apk`.
- [ ] Release AAB export preset prepared before Play upload.
- [ ] Version code incremented for every Play upload.
- [ ] Release signing configured outside the repository.

## Project Metadata

- [ ] App name is Reptile Tycoon.
- [ ] Package name is `com.makssnake.reptiletycoon`.
- [ ] Version name is correct.
- [ ] Orientation is portrait.
- [ ] App icon prepared.

## QA

- [ ] First launch passes.
- [ ] Save/load passes.
- [ ] Offline progress passes.
- [ ] Pause/resume passes.
- [ ] Core assets load on Android.
- [ ] No critical console errors.
- [ ] No critical crash on Android.

## Google Play

- [ ] Prepare final app icon 512x512.
- [ ] Prepare feature graphic 1024x500.
- [ ] Capture phone screenshots.
- [ ] Privacy policy hosted.
- [ ] Prepare AAB export.
- [ ] Create Play Console app.
- [ ] Fill store listing.
- [ ] Data Safety completed from actual build.
- [ ] Content rating completed.
- [ ] Store descriptions PL/EN ready.
- [ ] Screenshots ready.
- [ ] Feature graphic ready.
- [ ] Contact email ready.
- [ ] Closed testing group ready.
- [ ] Upload first AAB.
- [ ] Run tester feedback cycle.
- [ ] Fix critical issues.
- [ ] Increment version code for each uploaded build.

Verify current Google Play Console testing and submission requirements directly in Play Console before submission.

## Scope Guard

- [ ] No ads declared unless implemented.
- [ ] No IAP declared unless implemented.
- [ ] No Play Games Services declared unless implemented.
- [ ] No analytics declared unless implemented.
- [ ] No cloud save declared unless implemented.
