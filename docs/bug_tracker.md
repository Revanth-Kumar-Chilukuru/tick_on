# TickOn Bug Tracker

This document tracks bugs encountered during development, their causes, and how they were fixed.

### 1. Home Screen Cards Overlap Bug
**Issue:** The "Completed" and "Wall of Shame" cards at the bottom of the home screen overlapped the "No active routines" empty state text when scrolling.
**Cause:** The empty state text was inside the scroll view, but the cards had semi-transparent backgrounds and were gliding over the text, causing a messy visual overlap.
**Fix:** Removed the large cards from the home screen entirely. Transitioned the app to a `BottomNavigationBar` architecture, giving dedicated tabs to Home, Completed, and Wall of Shame. This cleaned up the UI and prevented any scroll-clashing.

### 2. Android Manifest XML Missing Tag
**Issue:** Build failed with `Error parsing LocalFile: AndroidManifest.xml`.
**Cause:** When automatically injecting the Notification permissions, the `<activity>` tag was accidentally removed due to a flawed file replacement.
**Fix:** Completely rewrote the `AndroidManifest.xml` to restore the correct syntax and activity layout.

### 3. Flutter Local Notifications Desugaring Error
**Issue:** Build failed with `CheckAarMetadataWorkAction` complaining about missing core library desugaring for `flutter_local_notifications` v20.1.0.
**Cause:** The notification library requires Java 8+ features natively supported on older Android devices via desugaring.
**Fix:** Enabled `isCoreLibraryDesugaringEnabled = true` in `android/app/build.gradle.kts` and added the `desugar_jdk_libs:2.1.4` dependency.
