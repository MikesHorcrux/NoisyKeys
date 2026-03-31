# Noisy Keys Roadmap

## Product Direction

Noisy Keys is a paid Mac app that turns typing into piano.

The core product is:

- simple to understand
- fun to keep open
- musical instead of random
- polished enough to feel worth paying for

For v1, the product is intentionally narrow:

- English only
- macOS 13+
- best on standard US keyboard layouts
- piano-first, not a giant sound pack app

## Current State

The app is now in launch-candidate shape.

### Built

- Global keyboard listening across macOS with Input Monitoring
- Menu bar controller
- Main app dashboard
- Onboarding flow
- 4 curated piano sounds:
  - `Grand Room`
  - `Felt Bloom`
  - `Jazz Club`
  - `Midnight Blue`
- `Custom Mix` piano mode
- Adaptive note-family learning for letters
- Phrase-based piano mapping instead of flat per-key note jumps
- Typing-speed and text-tone performance shaping
- App icon and menu bar icon
- README and technical docs

### Product Principle

The app should sound like piano performance, not keyboard click effects.

## V1.0: Ship The Piano App

### Goal

Ship the first public version as a focused piano typing app.

### Scope

- Keep the 4 curated piano sounds as the main product
- Keep `Custom Mix` as a secondary advanced option
- Keep onboarding short and clear
- Keep permissions obvious and easy to recover from
- Keep the menu bar experience equal in quality to the main app
- Keep the sound stable and musical during fast typing

### Launch Checklist

- Final archive and release-build smoke test
- Verify Input Monitoring flow on a clean machine
- Verify menu bar reopen behavior
- Verify global typing still works with no main window visible
- Verify sound toggle off/on and relaunch persistence
- Final App Store assets:
  - icon
  - screenshots
  - subtitle
  - description
  - keywords
  - privacy/support links

### V1 Non-Goals

- No localization yet
- No non-US keyboard-layout support yet
- No lo-fi relaunch in the shipping surface yet
- No genre packs
- No cloud features
- No social or recording layer

## V1.1: Launch Follow-Up

### Goal

Tighten what users touch first after release.

### Focus

- Fix launch bugs from real usage
- Improve onboarding clarity where users hesitate
- Tighten App Store copy and screenshots based on conversion
- Add better empty/error states if permission flow still confuses people
- Clean up analytics-free product signals such as support feedback and reviews

## V1.2: International Readiness

### Goal

Prepare the app for broader language and keyboard support.

### Planned Work

- Move all user-facing copy into localization resources
- Support additional keyboard layouts beyond US ANSI
- Revisit mood inference so it is not English-only
- Rename or reframe speed metrics where `WPM` is not ideal
- Add first-pass localization for high-value launch languages

## V2.0: Sound Expansion

### Goal

Expand the sound world without diluting the core piano product.

### Planned Work

- Reintroduce lo-fi as a deliberate second sound family
- Add curated alternate sound packs instead of endless modes
- Keep profiles fixed and intentional, not noisy or random
- Add more playback personalities only if they sound truly distinct

### Guardrails

- New sounds must feel premium, not like filler
- The app should stay simple on the surface
- Sound count should never outrun quality

## V2.1: Better Musical Intelligence

### Goal

Make phrasing feel even more like performance.

### Planned Work

- Better phrase resolution
- Stronger chord-bed logic
- Better left-hand support ideas
- More graceful sustain and cadence behavior
- More refined burst-to-burst emotional continuity

## Long-Term Ideas

- Additional curated sound families
- Better international keyboard support
- Accessibility tuning for sound density and volume behavior
- Optional recording/export ideas
- User-created or shareable custom sound presets

## Always True

- Keep the app joyful
- Keep the UI simple
- Keep the sound musical
- Keep the product small enough to stay polished
