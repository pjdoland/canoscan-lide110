# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Regenerate Xcode project from project.yml (required after changing project structure)
xcodegen generate

# Debug build
xcodebuild -project CanoScanLiDE110.xcodeproj -scheme CanoScanLiDE110 -configuration Debug build

# Release build
xcodebuild -project CanoScanLiDE110.xcodeproj -scheme CanoScanLiDE110 -configuration Release -derivedDataPath build
```

No tests, linting, or CI are configured.

## Architecture

Two-layer MVVM app: a local Swift package (`ScannerKit`) for core logic, and a SwiftUI app target (`CanoScanLiDE110`) for UI.

**ScannerKit** (local Swift package) contains all non-UI logic:
- `ScannerManager` (actor) — runs `scanimage -L` for detection and `scanimage --format=tiff ...` for scanning, returning raw TIFF data on stdout
- `ProcessRunner` (actor) — async `Process` wrapper. Reads stdout/stderr on background threads *before* waiting for termination to avoid pipe buffer deadlocks with large image data
- `ImageConverter` — converts raw TIFF to PNG/JPEG/PDF using AppKit and PDFKit
- `SANEPathResolver` — checks `/opt/homebrew/bin/scanimage` (ARM) then `/usr/local/bin/scanimage` (Intel)

**App target** consumes ScannerKit:
- `ScannerViewModel` (`@MainActor ObservableObject`) — state machine (idle/scanning/error), holds scanned pages as raw TIFF `Data`, orchestrates scan/export
- Views get the VM via `@EnvironmentObject`

Data flow: User action → `ScannerViewModel` → `ScannerManager` → `ProcessRunner` → `scanimage` subprocess → TIFF data → `ImageConverter` (on export) → file

## Key Constraints

- **macOS 13+ deployment target** — avoid macOS 14+ APIs (no `ContentUnavailableView`, no `MagnifyGesture`; use `MagnificationGesture` instead)
- **Non-sandboxed** (`ENABLE_APP_SANDBOX=NO`) — required to execute Homebrew binaries
- **`GENERATE_INFOPLIST_FILE=YES`** — no manual Info.plist; Xcode generates it from build settings
- **XcodeGen** — the `.xcodeproj` is generated from `project.yml`; edit that file for project structure changes, then run `xcodegen generate`
- Scanner-specific code is minimal (just string matching in `ScannerManager.detectScanner()`); the rest is scanner-agnostic
