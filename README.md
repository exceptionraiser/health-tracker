# Training Log — iOS

A personal fat-loss training log for iPhone. One user, one goal, zero friction.

## What it does

- **Daily assignment + checklist** — see today's workout and diet tasks and tick them off.
- **Morning weigh-ins** — log your weight each morning in seconds.
- **Progress chart** — 7-day rolling average with a **199 lb goal line**, so day-to-day noise doesn't hide the trend.
- **Milestones** — celebrate checkpoints on the way down.
- **Full training & diet plan** — the complete plan is built into the app for reference.

All data is stored **on-device**. No accounts, no network, no tracking.

## Tech

- SwiftUI + Swift Charts
- Project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`TrainingLog/project.yml`)
- iOS 16.0+, no external package dependencies

## Build locally

```sh
brew install xcodegen
xcodegen generate --spec TrainingLog/project.yml --project TrainingLog
open TrainingLog/TrainingLog.xcodeproj
```

Then select the **TrainingLog** scheme in Xcode and run on a simulator, or on your own device (set your personal team under Signing & Capabilities to run on hardware).

## Releases

- **Every push** touching `TrainingLog/**` runs the [Build iOS App](.github/workflows/build-ios.yml) workflow on GitHub Actions and uploads an **unsigned** `TrainingLog-unsigned.ipa` as a workflow artifact.
- **Pushing a `v*` tag** (e.g. `v1.0.0`) additionally creates a GitHub Release with the `.ipa` attached.

## Installing the unsigned IPA

The CI-built `.ipa` is **not code-signed**, so it cannot be installed on a device as-is — iOS requires every app to be signed. Options:

- **AltStore** or **Sideloadly** — sideload the `.ipa`; these tools re-sign it with your Apple ID (free accounts require re-signing every 7 days).
- **Xcode** — clone the repo, generate the project, set your own team, and run directly on your device.
