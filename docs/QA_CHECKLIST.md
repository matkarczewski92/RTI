# QA Checklist

Use this checklist for Reptile Tycoon MVP Android and release-readiness testing.

## Android debug test - passed manually

- Date: TODO
- Device: TODO
- APK version: `0.1.0-debug`
- Tester: Mateusz Karczewski
- Notes: TODO

Passed in the current manual Android phone test:

- [x] APK installs.
- [x] Game launches.
- [x] Portrait orientation works.
- [x] Main biome view loads.
- [x] Background graphics load on Android.
- [x] Top bar is visible.
- [x] Bottom menu is visible.
- [x] Touch input works.
- [x] Habitat purchase/build works.
- [x] Habitat management opens.
- [x] Reptile shop works.
- [x] Reptile assignment works.
- [x] Reptile management opens.
- [x] Care actions work.
- [x] Quest screen opens.
- [x] Achievement screen opens.
- [x] Save/load works.
- [x] Offline progress works.
- [x] Minimize/resume works.
- [x] No blocking crash found in current manual test.

## First Launch

- [x] App starts.
- [ ] Welcome screen is visible.
- [x] Portrait orientation is active.
- [x] No missing welcome/background asset.
- [ ] No missing main UI assets.

## Navigation

- [ ] Welcome screen opens biome map.
- [ ] Biome map opens Green Meadow.
- [ ] Bottom menu opens biome map.
- [ ] Bottom menu opens current biome.
- [ ] Bottom menu opens animals.
- [x] Bottom menu opens shop.
- [x] Bottom menu opens quests.
- [ ] Bottom menu opens upgrades.
- [ ] Settings opens.
- [ ] Settings closes.

## Habitat Flow

- [x] Buy habitat.
- [x] Construction starts.
- [ ] Timer displays seconds below 1 minute.
- [ ] Habitat becomes usable after construction.
- [x] Habitat can be managed.
- [ ] Habitat can be removed if allowed.
- [ ] Upgrade is blocked if reptile is assigned.
- [ ] Upgrade starts after reptile is removed.
- [ ] In-progress habitat uses `in_progress.png`.

## Reptile Flow

- [x] Buy reptile in shop.
- [ ] Choose common/rare.
- [ ] Correct rarity icon appears.
- [ ] Choose sex.
- [ ] Name reptile.
- [x] Assign reptile to habitat.
- [ ] Unassign reptile.
- [ ] Reptile remains after save/load.

## Reptile Management

- [x] Reptile management opens correctly.
- [ ] Portrait has no unwanted frame/background.
- [ ] Edit name popup is clickable above modal.
- [x] Care buttons work.
- [ ] Needs update.
- [ ] Income display updates.
- [ ] Remove reptile works.
- [ ] Upgrade habitat message works.

## Economy

- [ ] R$ changes from active income.
- [ ] Income progress bars work.
- [x] Offline income popup works.
- [ ] Rewards add correctly.
- [ ] Rewards do not duplicate.

## Quests

- [ ] Quest progress updates.
- [ ] Rewards claim correctly.
- [ ] Reward popup OK is clickable immediately.
- [ ] Rewards do not duplicate.
- [ ] Reach-level quests work.

## Achievements

- [ ] Progress updates.
- [ ] Rewards claim correctly.
- [ ] Reward popup OK is clickable immediately.
- [ ] Harder achievements have better rewards.
- [ ] Rewards do not duplicate.

## XP / Levels

- [ ] XP increases.
- [ ] Level 2 unlocks at 1000 XP.
- [ ] Level 3 unlocks at 3000 XP.
- [ ] Higher thresholds follow the project formula.
- [ ] Level-up popup appears.
- [ ] Top bar updates.
- [ ] Level rewards add once.

## Workers / Upgrades

- [ ] Workers screen opens.
- [ ] Upgrades screen opens.
- [ ] Purchase/upgrade works if implemented.
- [ ] Effects apply if implemented.
- [ ] Save/load works.

## Settings

- [ ] Language switch works.
- [ ] PL/EN persists.
- [ ] Music toggle persists if implemented.
- [ ] SFX toggle persists if implemented.
- [ ] Vibration toggle persists if implemented.
- [ ] Reset game requires confirmation.
- [ ] Reset works.

## Android-specific

- [x] APK installs.
- [x] App launches.
- [x] No crash on minimize/resume.
- [x] UI is touch-friendly.
- [x] Save persists after app close.
- [x] Offline progress works after app close.
- [x] Assets load on Android with exact case-sensitive paths.

## Regression

- [ ] No critical console errors.
- [ ] No missing asset warnings for core UI/backgrounds.
- [ ] No broken black popup overlays.
- [ ] No input-blocking modal bugs.
- [ ] No ads visible.
- [ ] No IAP or premium purchase UI visible.
