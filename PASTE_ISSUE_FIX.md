# Clipy Paste Functionality Fix After Rebuild

## Issue Description
After rebuilding the Clipy app with `./build.sh`, the paste functionality fails even though the app builds successfully. This is a common issue with macOS applications that require accessibility permissions.

## Root Causes Identified

1. **Code Signature Changes**: When the app is rebuilt, the code signature changes, which invalidates previously granted accessibility permissions.

2. **Build Path Issues**: The original build script was copying from an incorrect path (`./.build/arm64-apple-macosx/debug/Clipy` instead of the actual build output path).

3. **Permission Detection**: The app didn't properly detect when it was recently rebuilt and needed new permissions.

## Fixes Implemented

### 1. Fixed Build Script Path Issue
**File**: `build.sh`
- Changed from hardcoded path to dynamic path detection using `swift build --show-bin-path`
- This ensures the correct binary is always copied to the app bundle

### 2. Enhanced Paste Service Permission Handling
**File**: `src/Services.swift`
- Added `checkIfAppWasRecentlyRebuilt()` method to detect when app was built within the last hour
- Added `showPermissionGuidanceForRebuiltApp()` to provide specific guidance for rebuilt apps
- Enhanced launch method detection to be more robust

### 3. Improved User Experience
- The app now detects when it was recently rebuilt and shows specific guidance
- Provides direct link to open System Preferences for re-granting permissions
- Clear instructions on how to restore paste functionality

## How the Fix Works

1. **Build Time Detection**: The app checks if the bundle was modified within the last hour
2. **Permission Status**: Combines rebuild detection with accessibility permission status
3. **User Guidance**: Shows specific instructions for rebuilt apps that need permissions
4. **Graceful Fallback**: Always copies content to clipboard even if paste fails

## Usage After Fix

After rebuilding with `./build.sh`:

1. **If permissions are lost**: The app will automatically detect this and show guidance
2. **Manual steps**: Follow the dialog to re-grant accessibility permissions
3. **Direct launch**: Use `./Clipy.app/Contents/MacOS/Clipy` for best results
4. **Fallback**: Content is always copied to clipboard for manual paste with ⌘+V

## Prevention

To minimize permission issues:
- Use `codesign` with proper developer certificates in production
- Consider using consistent signing during development
- Document the permission requirements clearly for users

## Technical Details

The key improvements are:
- Dynamic build path detection
- Recent rebuild detection via file modification timestamps
- Enhanced permission guidance with direct system preferences access
- Robust fallback mechanisms

This fix addresses the core issue where macOS revokes accessibility permissions when an app's code signature changes during rebuild.