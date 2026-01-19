# miniageOS (mini-LineageOS)

Create a stripped-down "dumbphone" version of LineageOS for your Google Pixel without giving up the camera quality and touchscreen of a smartphone.

> dumbphone _(noun)_: A phone that is actually just a phone and only does what you need it to do for day-to-day life.

<p align="center">
  <img src="https://github.com/user-attachments/assets/610abed4-f7a7-40e7-82b7-b2491f2bd7f1" alt="app-list" width="60%" />
</p>

_<p align="center">Launcher shown is Olauncher (not included but recommended)</p>_

## What is this?

Scripts, and resources used by those scripts to do what it does (see "What it does")

## What is it _not_?

- A launcher
- "Screen time"-like restrictions
- Temporary, reversible commands that disable certain apps, which can be trivially re-enabled in Settings or when the phone gets an update
- A fork of LineageOS (it builds the official, up-to-date LineageOS, with modifications being made at build time)

## What it does

- Builds the system image without any browser
- Compiles with a custom hosts file so that your phone will "hard-block" any domains you choose
- UI changes:
  - Sets the phone to grayscale and night mode (blue light filter)
  - Applies a magnifier to text and UI elements on the phone to encourage holding it further away and protecting eyesight
  - Disables animations
- Builds without the user-facing "Updater" so that you will not overwrite changes made to the operating system with OTA updates
- Does not include any app store or Google Play Services in the system image (like official LineageOS)
- Pulls the most recent LineageOS updates and device-specific vendor updates from their official sources before building, so each build is up to date with the official project
- Preserves all existing apps, settings, and other user data on phones that already have LineageOS installed
- After the modified LineageOS image is built and flashed to your phone, it auto-downloads and installs the Aurora Store temporarily from a reputable source (F-droid), waits for you to update or install any apps you need (like secure messaging, notes, and maps), then auto-uninstalls the store when you are done
- Replaces the default LineageOS camera app with the Google Pixel camera app for higher quality photos without needing GApps/Google Play Services
- Disables unnecessary machine learning-based apps that use excessive data and battery power (Android System Intelligence and Private Compute Services)
- Option to selectively exclude certain Google/carrier software from the build by preventing their "blobs" from being extracted, such as the "OK Google" listening software and Verizon apps
- Replaces the default LineageOS camera app with the Google Pixel camera app for higher quality photos without needing GApps/Google Play Services
- Disables unnecessary machine learning-based apps that use excessive data and battery power (Android System Intelligence and Private Compute Services)
- Option to selectively exclude certain Google/carrier software from the build by preventing their "blobs" from being extracted, such as the "OK Google" listening software and Verizon apps
- No need for root access to make any of these changes
- Drastically increases battery life and reduces data usage just by virtue of the phone doing less and having less on it

## ⚠️ Disclaimer ⚠️

- As of now, these scripts have only been tested on a Google Pixel 7a. While they are likely compatible with other Pixel models, I cannot guarantee this conclusively until tested. For non-Pixel phones, it is **untested** and could have **destructive results**, or simply fail before completing the build due to differences in build processes, file locations, etc.
- At this point in time, I do _not_ recommend trying to use this build system for any phone other than a Google Pixel.

## Prerequisites

- A computer running Unix/Linux (either natively or in a VM)
  - ✅ Yes: Linux
  - ❔ Maybe: macOS or WSL (may require workarounds)
  - ❌ No: Windows
- At least 16GB RAM (adjust SWAP accordingly)
- At least 300GB storage, either on your regular SSD or an external USB one
  - In lieu of the above hardware/OS requirements, you could build on an EC2 instance or similar, then copy the build output files to your local machine and flash from there.
- Have official LineageOS already installed on your phone
  - Note: installing LineageOS for the first time will wipe your phone
  - Guide at https://wiki.lineageos.org/devices/{your-device-code-name}/install/
- Have followed the LineageOS "Build for {your-device-code-name}" guide on their wiki, up to the "Preparing the build environment" section and have run "repo sync" at least once before
  - Guide at https://wiki.lineageos.org/devices/{your-device-code-name}/build/

## Instructions

1. Clone this repo:

```bash
git clone https://github.com/ofdryads/miniageos.git
cd miniageos
```

2. Configure:

- Enter the correct values in config-example.sh, then rename or copy config-example.sh to a file called "config.sh" in that same folder
- Put any and all domains you want to block in the hosts file at replace/hosts

3. Make the scripts executable:

```bash
chmod +x sync-mod-build.sh flash-customize.sh
```

4. Run

```bash
./sync-mod-build.sh
```

5. Once the build has completed, run:

```bash
./flash-customize.sh
```

## Issues

- When running ./extract-files.py pointing at the official LineageOS release zip (at least for Pixel 7a), extracting the blobs will fail because of an error from "osaifu-ketai.patch", which iirc references a file that is not where it expects it to be. This patch is related to a specific Japanese NFC provider that is not relevant to most Pixel phones. The issue can be bypassed by commenting out the lines under the "FeliCa" section in the "proprietary-files.txt" file.

## Which modifications need to be re-applied with each build vs. which are one-and-done?

### Repeated each build:

- Hosts file additions
  - Why: repo sync will overwrite. However, _you_ do not need to do anything for repeat builds, so long as the HOSTS config variable points to a saved custom hosts file on your computer that is outside the LineageOS source code folder
- Disabling saved settings searches
  - Why: repo sync will overwrite
- Blob extraction
  - Why: Google firmware gets updates occasionally
- Install -> uninstall Aurora Store to check for app updates (if any 3rd party apps were installed from there)
  - Why: Vulnerabilities in un-updated apps

### One-time changes:

- Editing proprietary-files.txt
- Grayscale/night mode/animations/UI magnifier

**For changes that do not need to be re-applied each build, you can set these variables to "false" in config.sh _after they have been applied through an initial build/flash_, and the scripts will simply skip these steps while preserving their current state**

## What will _not_ work when using a phone running this build?

- Banking apps, Venmo, NFC/contactless pay (like Google Pay, Apple Pay, or Samsung Pay)
- RCS messaging
  - However, regular SMS, most messaging apps (Signal, WhatApp), and iMessage proxy services (OpenBubbles/BlueBubbles) _will_ work just fine
- _(The points above apply to any phone with an unlocked bootloader, including ones running official LineageOS builds)_
- Opening links (URL or QR code) in a browser will not work, since there is no browser to open the links.
- If using a third party messaging app, I _highly_ recommend installing MicroG to be able to get push notifications. You can get the literal messages without it, but not the notifications.

## Important note

This is meant to be repeated every few months or so. Running this script/flashing the image _is_ the update mechanism. It replaces the OTA system to avoid the modifications being undone by official LineageOS releases. Going 6+ months without updating creates security risks. This goes for any 3rd party apps you add as well.
