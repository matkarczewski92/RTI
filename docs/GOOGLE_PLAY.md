# Google Play Preparation

This document tracks Google Play preparation for the first Reptile Tycoon testing/publication phase.

## App Identity

- App name: Reptile Tycoon.
- Package name: `com.makssnake.reptiletycoon`.
- Current debug version name: `0.1.0-debug`.
- Current debug version code: `1`.
- Suggested category: Game / Simulation or Casual / Simulation.
- Target audience note: casual mobile players interested in tycoon, idle, collection, and cozy animal management games.
- Current MVP account model: no user account, local save only.
- Current monetization state: no ads and no in-app purchases implemented.

## Store Listing Assets Needed

- App icon: 512x512.
- Adaptive icon foreground/background if needed later.
- Feature graphic: 1024x500.
- Phone screenshots.
- Optional tablet screenshots later if tablet support is intentionally polished.
- Short description PL/EN.
- Full description PL/EN.
- Privacy policy URL before publication.
- Contact email.
- App version and changelog.

Asset working folder:

```text
assets/art/google_play/
```

## Screenshot Plan

Capture screenshots after the UI is stable on Android:

- [ ] Welcome screen.
- [ ] Biome map.
- [ ] Green Meadow biome screen.
- [ ] Habitat management / reptile management.
- [ ] Shop.
- [ ] Animals / collection.
- [ ] Quests.
- [ ] Workers / upgrades if visually ready.

Do not show systems that are not available in the uploaded build.

## Store Text Placeholders

### PL Short Description

Zbuduj własne centrum gadów, rozwijaj habitaty, odkrywaj warianty i zarabiaj R$.

### EN Short Description

Build your reptile center, upgrade habitats, discover variants and earn R$.

### PL Full Description Draft

Reptile Tycoon to przyjazna gra idle tycoon o zarządzaniu gadami. Buduj i rozwijaj habitaty, kupuj nowe gady, odkrywaj warianty kolorystyczne i powiększaj swoją kolekcję.

Opiekuj się zwierzętami, wykonuj zadania, zdobywaj XP, zwiększaj poziom gracza i rozwijaj Zieloną Polanę. Twoje gady generują idle income, a po powrocie do gry możesz odebrać offline progress.

W aktualnym MVP gra nie wymaga konta użytkownika. Postęp jest zapisywany lokalnie na urządzeniu.

Funkcje MVP:
- zarządzanie gadami,
- habitaty,
- warianty kolorystyczne,
- zadania,
- poziom gracza i XP,
- idle income,
- offline progress,
- lokalny zapis gry.

### EN Full Description Draft

Reptile Tycoon is a cozy idle tycoon game about reptile management. Build and upgrade habitats, buy new reptiles, discover color variants, and grow your collection.

Care for your reptiles, complete quests, earn XP, increase your player level, and develop Green Meadow. Your reptiles generate idle income, and when you return to the game you can collect offline progress.

The current MVP does not require a user account. Progress is saved locally on the device.

MVP features:
- reptile management,
- habitats,
- color variants,
- quests,
- player level and XP,
- idle income,
- offline progress,
- local save.

## Closed Testing Checklist

Do not hardcode final legal or current Google Play testing requirements as permanent facts. Before submission:

- [ ] Verify current Google Play Console testing requirements directly in Play Console.
- [ ] Prepare a tester group.
- [ ] Prepare install and feedback instructions.
- [ ] Upload an AAB to the appropriate testing track.
- [ ] Collect device, OS, crash, UI, and gameplay feedback.
- [ ] Upload fixed builds as needed.
- [ ] Increment version code for every uploaded build.

Suggested tester focus:

- first launch,
- welcome to biome flow,
- habitat purchase,
- shop purchase,
- reptile assignment,
- save/load,
- offline progress,
- pause/resume,
- portrait lock,
- missing assets or black overlays,
- UI touch comfort.

## Data Safety Preparation

Current MVP assumption:

- no account system,
- no backend/server,
- no ads,
- no in-app purchases,
- no analytics,
- local save only.

Before publication, verify the actual shipped build and complete Google Play Data Safety based on the real SDKs, permissions, network behavior, and data handling at that time.

## Release Checklist

- [ ] AAB builds successfully.
- [ ] Version code increments.
- [ ] Version name is correct.
- [ ] Package name is `com.makssnake.reptiletycoon`.
- [ ] Privacy policy ready and hosted.
- [ ] Data Safety form prepared from the actual build.
- [ ] Content rating completed.
- [ ] Screenshots ready.
- [ ] Store descriptions PL/EN ready.
- [ ] Contact email ready.
- [ ] No debug/test UI visible.
- [ ] No critical crash on Android.
- [ ] Save/load works.
- [ ] Offline progress works.
- [ ] App stays portrait.
- [ ] No ads declared if ads are not implemented.
- [ ] No IAP declared if purchases are not implemented.

## Next Steps

- [ ] Prepare final app icon 512x512.
- [ ] Prepare feature graphic 1024x500.
- [ ] Capture phone screenshots.
- [ ] Publish privacy policy URL.
- [ ] Prepare AAB export.
- [ ] Create Play Console app.
- [ ] Fill store listing.
- [ ] Fill Data Safety according to actual app behavior.
- [ ] Fill content rating.
- [ ] Prepare closed/internal testing group.
- [ ] Upload first AAB.
- [ ] Run tester feedback cycle.
- [ ] Fix critical issues.
- [ ] Increment version code for each uploaded build.

Verify current Google Play Console testing and submission requirements directly in Play Console before submission. Do not treat this checklist as a fixed legal or policy statement.
