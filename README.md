# Training Log — iOS

A personal fat-loss training log for iPhone. One user, one goal, zero friction.

## What it does

- **Daily assignment + checklist** — see today's workout and diet tasks and tick them off.
- **Morning weigh-ins** — log your weight each morning in seconds, with a **daily reminder** so you don't forget.
- **Backfill** — missed a few days? Enter weigh-ins for any date up to **30 days back**.
- **Progress chart** — 7-day rolling average on a **real date axis**, with a **199 lb goal line** and a **next-milestone target line** so day-to-day noise doesn't hide the trend.
- **Milestones** — celebrate checkpoints on the way down.
- **Weekly adherence + streak** — how many days this week you did the work, and how long the run is.
- **Plateau check** — stall detection flags when the trend has flattened so you can adjust early.
- **Waist log** — track waist measurements alongside weight.
- **Progression memory** — the app remembers what you did last time and tags exercises **↑ HARDER** when it's time to push.
- **Week-alternating A/B suggestions** — sessions rotate between A and B variants week to week.
- **Warm-up, mobility, functional and diet content built in** — the complete plan is in the app for reference; nothing to look up elsewhere.
- **CSV / JSON export** — your data is yours; export it any time.

All data is stored **on-device**. No accounts, no network, no tracking.

## Tech

- SwiftUI + Swift Charts
- Project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`TrainingLog/project.yml`)
- iOS 16.0+, no external package dependencies
- Bundle ID `com.exceptionraiser.traininglog`, version 1.1.0

## Build locally

```sh
brew install xcodegen
xcodegen generate --spec TrainingLog/project.yml --project TrainingLog
open TrainingLog/TrainingLog.xcodeproj
```

Then select the **TrainingLog** scheme in Xcode and run on a simulator, or on your own device (set your personal team under Signing & Capabilities to run on hardware).

## Releases

- **Every push** touching `TrainingLog/**` runs the [Build iOS App](.github/workflows/build-ios.yml) workflow on GitHub Actions and uploads an **unsigned** `TrainingLog-unsigned.ipa` as a workflow artifact.
- **Pushing a `v*` tag** (e.g. `v1.1.0`) additionally creates a GitHub Release with the `.ipa` attached, and triggers the [TestFlight](.github/workflows/testflight.yml) workflow (see below).

## Installing the unsigned IPA

The CI-built `.ipa` is **not code-signed**, so it cannot be installed on a device as-is — iOS requires every app to be signed. Options:

- **TestFlight** — the supported path; see the next section. Builds are signed by Apple and install like any App Store app.
- **AltStore** or **Sideloadly** — sideload the `.ipa`; these tools re-sign it with your Apple ID (free accounts require re-signing every 7 days).
- **Xcode** — clone the repo, generate the project, set your own team, and run directly on your device.

## TestFlight

The [TestFlight](.github/workflows/testflight.yml) workflow archives the app with Apple's **cloud-managed automatic signing** and uploads it straight to App Store Connect. No certificates or provisioning profiles are stored in the repo — Xcode creates and manages them using an App Store Connect API key.

### One-time setup

1. **Apple Developer Program** — you need a paid membership (TestFlight is not available on free accounts).

2. **App Store Connect API key** — in [App Store Connect](https://appstoreconnect.apple.com) go to **Users and Access → Integrations → App Store Connect API** and generate a **Team key** with the **Admin** role. Admin is required so Xcode can create the cloud-managed distribution certificate and profile on your behalf. Download the `.p8` file — **it can only be downloaded once** — and note the **Key ID** and the **Issuer ID** shown on that page.

3. **Team ID** — find it at [developer.apple.com/account](https://developer.apple.com/account) → **Membership details** (a 10-character string like `AB12CD34EF`).

4. **Create the app record** — in App Store Connect go to **Apps → "+" → New App**:
   - Platform: **iOS**
   - Name: **Training Log**
   - Primary language: your choice
   - Bundle ID: **`com.exceptionraiser.traininglog`** — if it isn't offered in the dropdown, register it first under [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list) → **App IDs** (explicit bundle ID, no extra capabilities needed), then come back.
   - SKU: anything unique, e.g. `traininglog`

5. **GitHub repository secrets** — in the repo go to **Settings → Secrets and variables → Actions** and add four secrets:

   | Secret | Value |
   |---|---|
   | `APPLE_TEAM_ID` | Team ID from step 3 |
   | `ASC_KEY_ID` | Key ID from step 2 |
   | `ASC_ISSUER_ID` | Issuer ID from step 2 |
   | `ASC_API_KEY_P8` | The `.p8` file, **base64-encoded** — on macOS: `base64 -i AuthKey_XXXXXXXXXX.p8 \| pbcopy`, then paste |

6. **Run the workflow** — either open the **Actions** tab, pick **TestFlight**, and click **Run workflow**, or push a `v*` tag:

   ```sh
   git tag v1.1.0 && git push origin v1.1.0
   ```

7. **Install on your iPhone** — in App Store Connect open **TestFlight** for the app. The build appears after Apple finishes processing (usually 5–15 minutes). Under **Internal Testing** create a group (or use the default), add yourself as a tester, then install the **TestFlight** app from the App Store on your phone, accept the email invite, and tap **Install**.

### Notes

- **Internal testing needs no App Review** — builds are available to internal testers as soon as processing finishes.
- **Build numbers auto-increment** — `CURRENT_PROJECT_VERSION` is set to the GitHub Actions run number, so every run produces a higher build number for the same marketing version (1.1.0). Each new tag or manual run pushes a new build to TestFlight.
- **Missing secrets are harmless** — the workflow's `preflight` job checks that all four secrets exist. If any are missing it prints a notice naming them and skips the upload, so tagging a release before finishing setup is fine; the unsigned `.ipa` release still builds via the Build iOS App workflow.
- **Debugging a failed upload** — the `testflight-export-logs` artifact contains `DistributionSummary.plist`, `ExportOptions.plist`, and the export logs from the run.
- **Rotating the key** — if you revoke the API key in App Store Connect, generate a new one and update `ASC_KEY_ID` and `ASC_API_KEY_P8` (the Issuer ID stays the same for your team).
