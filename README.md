# MdReader

A minimal, native macOS app for viewing and editing Markdown (`.md`) files. Built with Swift and SwiftUI.

- **View** tab — renders the Markdown (headings, bold/italic, links, inline code, lists, blockquotes, code blocks, and tables).
- **Edit** tab — shows and edits the raw Markdown text.
- One file open at a time, in one window — open another file or close the current one without quitting the app.
- Registered as a handler for `.md` files, so it shows up in Finder's "Open With" and can be the default app for Markdown files.

## Download and install

1. Go to the [Releases page](https://github.com/rejeevd/MdReader/releases/latest) and download `MdReader.zip` from the latest release.
2. Double-click the zip to unzip it (or run `unzip MdReader.zip`), producing `MdReader.app`.
3. Drag `MdReader.app` into your `/Applications` folder (or open Finder's **Go > Applications** and drop it in).

### Opening the app the first time (unsigned app warning)

MdReader isn't signed with a paid Apple Developer ID, so macOS Gatekeeper will block a plain double-click the first time with a message like *"MdReader can't be opened because Apple cannot check it for malicious software."* This is expected for an app distributed outside the App Store. To open it anyway:

- **Right-click (or Control-click) `MdReader.app` in Finder → choose "Open"** → click **"Open"** again in the dialog that appears.

If that doesn't show an "Open" option, instead:

- Try double-clicking the app once (it will be blocked).
- Go to **System Settings → Privacy & Security**, scroll down to the security message about MdReader, and click **"Open Anyway"**.
- Confirm with your password/Touch ID if prompted.

You only need to do this once — after the first approval, MdReader opens normally (double-click, Spotlight, Dock, etc.).

## Using MdReader

- **Open a file:** `File > Open…` (⌘O), or double-click a `.md` file in Finder, or drag a `.md` file onto the MdReader Dock icon.
- **Switch views:** use the **View** / **Edit** segmented control at the top of the window.
- **New file:** `File > New` (⌘N).
- **Save / Save As:** `File > Save` (⌘S) / `File > Save As…` (⌘⇧S).
- **Close the current file:** `File > Close File` (⌘⇧W) — clears the window back to a blank, untitled state without closing the window or quitting the app.
- If you have unsaved changes and choose New, Open, or Close, you'll be prompted to save first.

## For developers

### Requirements

- macOS with Xcode (13+ deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Project layout

- `project.yml` — XcodeGen spec used to (re)generate `MdReader.xcodeproj`. Run `xcodegen generate` after pulling changes to `project.yml` to keep the checked-in `.xcodeproj` in sync.
- `MdReader/Sources/` — all Swift source, `Info.plist`, and `Assets.xcassets` (including the app icon)
- `logos/` — source logo/icon artwork
- `dist/` — packaged release zip (not committed)

### Build

Generate the Xcode project, then build with `xcodebuild`:

```sh
xcodegen generate
xcodebuild -project MdReader.xcodeproj -scheme MdReader -configuration Debug build
```

Or open `MdReader.xcodeproj` in Xcode after running `xcodegen generate` and hit Run.

### Package a Release build for distribution

```sh
# 1. Build Release
xcodegen generate
xcodebuild -project MdReader.xcodeproj -scheme MdReader -configuration Release build

# 2. Locate the built app (DerivedData path printed by xcodebuild, or query it):
APP=$(xcodebuild -project MdReader.xcodeproj -scheme MdReader -configuration Release -showBuildSettings 2>/dev/null | awk -F'= ' '/ BUILT_PRODUCTS_DIR /{print $2; exit}')/MdReader.app

# 3. Ad-hoc code sign (no paid Developer ID required)
codesign --force --deep --sign - "$APP"

# 4. Zip it for distribution, preserving the .app bundle structure
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/MdReader.zip
```

Upload `dist/MdReader.zip` as a release asset on GitHub (**Releases → Draft a new release → attach `MdReader.zip`**).

To test the build locally on your own Mac before releasing:

```sh
rm -rf /Applications/MdReader.app
cp -R "$APP" /Applications/MdReader.app
xattr -cr /Applications/MdReader.app
codesign --force --deep --sign - /Applications/MdReader.app
open /Applications/MdReader.app
```

### Notes on signing

This project is ad-hoc signed (`codesign --sign -`), which is free and lets the app run on any Mac, but triggers the Gatekeeper warning described above for anyone other than the machine it was built on. To distribute without that warning, you'd need an active Apple Developer Program membership to sign with a Developer ID certificate and notarize the build via `notarytool`.

## License

MIT — see [LICENSE](LICENSE).
