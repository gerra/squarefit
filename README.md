# SquareFit

A tiny iPhone app that makes photos square. Pick one or many photos, and each
one is padded with a white background to a perfect 1:1 square and saved as a
new image in your library. Originals are never modified.

- **Multi-select** with the system photo picker, no per-photo steps.
- **No downscaling**: the square's side equals the longer side of the original.
- **Least privilege**: the app only asks for *add-only* photo library access.
- No network, no analytics, no tracking. Privacy manifest included.

## Project layout

```
SquareFit.xcodeproj/            Xcode project (single iOS app target)
SquareFit/
  SquareFitApp.swift            App entry point
  ContentView.swift             UI: picker, preview grid, save bar
  SquareFitViewModel.swift      Loads picks, squares them, batch saves
  ImageSquarer.swift            The actual squaring (UIGraphicsImageRenderer)
  PhotoLibrarySaver.swift       Add-only PHPhotoLibrary saving
  Info.plist                    Permissions strings, orientation, encryption flag
  PrivacyInfo.xcprivacy         App privacy manifest
  Assets.xcassets/              App icon (1024x1024), accent + launch colors
Scripts/generate_icon.py        Regenerates the app icon with Pillow
```

Requires Xcode 15 or newer. Deployment target is iOS 17.

## Build and run

1. Open `SquareFit.xcodeproj` in Xcode.
2. Select the `SquareFit` target, then **Signing & Capabilities**.
3. Pick your **Team**. If the bundle ID `com.gerra.squarefit` is taken on
   your account, change it to something unique.
4. Choose a simulator or your iPhone and press Run.

## Upload to the App Store

1. In App Store Connect, create a new iOS app with the same bundle ID.
2. In Xcode choose **Any iOS Device (arm64)** as the destination.
3. **Product > Archive**.
4. In the Organizer window that appears, choose **Distribute App > App Store
   Connect > Upload** and accept the defaults.
5. Back in App Store Connect, fill in screenshots, description, and the
   privacy questionnaire (the app collects no data), then submit for review.

Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the target's build
settings for each new upload.

## Regenerating the icon

```
pip install Pillow
python3 Scripts/generate_icon.py
```

The output is a 1024x1024 opaque PNG with square corners, which is what App
Store Connect requires. Xcode generates every other icon size from it.
