# App Store Setup

This document explains how to go from the current Swift package plus checked-in iOS app project to a signed build that can be tested in TestFlight and submitted to the App Store.

## Current Reality

Today this repository gives you:

- shared Swift package code
- a shared SwiftUI app shell in `App/iOS`
- a committed iOS `.xcodeproj`
- a basic OpenAI-backed chat path using a developer key stored in Keychain
- core logic and UI you can reuse

Today it does **not** give you:

- production-safe API key architecture beyond the current developer-key prototype
- signing configuration
- finalized bundle and capability settings
- app icons and screenshot assets
- App Store Connect metadata

That means the App Store path now starts with hardening the existing Xcode app target instead of creating one from scratch.

## Phase 1: Run The Prototype First

Before creating the shipping app, make sure the package works locally.

```bash
xcrun swift test
xcrun swift run DopamineCLI
xcrun swift build
```

You should also open [Package.swift](/Users/kdio/codex/dopamine/Package.swift) in Xcode and run the `DopamineApp` scheme on `My Mac`.

## Phase 2: Open The Checked-In iOS App Host

1. Open Xcode.
2. Choose `File -> Open`.
3. Open `/Users/kdio/codex/dopamine/Dopamine.xcodeproj`.
4. If Xcode asks for an iOS platform/runtime, install it from `Xcode -> Settings -> Components` or `Platforms`.
5. Select the `Dopamine` scheme.
6. Choose an iPhone simulator and confirm the app launches.

## Phase 3: Maintain The Shared Project Wiring

The checked-in Xcode project already links the local package.

1. Keep `App/iOS` as the single source of truth for the app entry point.
2. Keep `Dopamine.xcodeproj` pointed at the local package dependency.
3. If you edit `project.yml`, regenerate the Xcode project with:

```bash
xcodegen generate
```

## Phase 4: Keep The App Host Thin

The checked-in iOS app should stay as a minimal wrapper around `DopamineUI`.

The current entry point pattern is:

```swift
import SwiftUI
import DopamineUI

@main
struct DopamineApp: App {
    var body: some Scene {
        WindowGroup {
            DopamineRootView()
        }
    }
}
```

Use the app host for platform concerns such as signing, capabilities, assets, and release configuration. Keep product logic in the package modules.

## Phase 5: Configure Signing

1. Select the app target.
2. Open `Signing & Capabilities`.
3. Sign in with your Apple Developer account in Xcode if needed.
4. Choose your Team.
5. Set a unique bundle identifier, for example `com.yourcompany.dopamine`.
6. Leave `Automatically manage signing` enabled unless you have a reason not to.

## Phase 6: Basic Release Metadata Inside Xcode

Set these values before the first archive:

- Display Name
- Bundle Identifier
- Version, for example `1.0.0`
- Build number, for example `1`
- App icon set
- Accent color and launch assets as needed
- Privacy usage strings if you access protected APIs

## Phase 7: Test On Simulator And Device

1. Install an iOS simulator runtime from `Xcode -> Settings -> Components` if none are installed.
2. Create an iPhone simulator in `Window -> Devices and Simulators` if Xcode has none yet.
3. Run the app on Simulator.
4. Run the app on a physical device if you have one.
5. Confirm:
   - launch works from a clean install
   - project rail and chat flow render correctly
   - no placeholder behavior blocks the main path

## Phase 8: Create The App Store Connect Record

In App Store Connect:

1. Create a new app.
2. Use the exact same bundle identifier as Xcode.
3. Set the app name, SKU, platform, and primary language.
4. Add support and privacy policy URLs.
5. Complete the App Privacy questionnaire.
6. Complete age rating and content-rights sections.

## Phase 9: Archive And Upload

1. In Xcode, choose an iOS device destination or `Any iOS Device`.
2. Choose `Product -> Archive`.
3. Wait for Organizer to open.
4. Validate the archive.
5. Upload the build to App Store Connect.

## Phase 10: TestFlight

1. Add internal testers.
2. Install the build from TestFlight.
3. Verify the real signed app, not just the package shell.
4. Fix issues and upload a new build if needed.

## Phase 11: Submit For Review

Before submission, make sure:

- screenshots match the current UI
- description and keywords are real, not placeholders
- privacy answers match real app behavior
- the support URL works
- there are no dead-end screens or unfinished flows

Then select the build in App Store Connect and submit it for review.

## Dopamine-Specific Release Gaps To Close First

Do not treat the current package as App Store-ready. These product gaps still need implementation work:

- persistent storage
- secure OpenAI key handling
- ChatGPT share-link import
- explicit user choice when demoting a project over the active cap
- production-ready onboarding and settings
