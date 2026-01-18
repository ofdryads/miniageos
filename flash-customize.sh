#!/bin/bash

script_in_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_folder="$LINEAGE_ROOT/out/target/product/$CODENAME"

function flash_recovery() {

  if ! command -v adb &> /dev/null; then
    echo "Error: adb not installed or not found on the computer - you can install adb/fastboot from Google"
    exit 1
  fi

  echo "Make sure your phone is plugged into the computer, and that USB debugging on this computer has been enabled and authorized (in developer settings)"
  device_list=$(adb devices)
  echo "$device_list"

  echo "If you see your device listed above, that is good and you can continue"
  echo ""
  echo "If you do not see any device listed, do NOT press Enter yet - troubleshoot, then come back when running 'adb devices' in another terminal window shows your device as 'device' (not 'unauthorized')"
  echo ""
  echo "Press Enter to continue to flash the new system image and recovery:"
  read -r _ < /dev/tty

  adb -d reboot bootloader

  fastboot flash vendor_boot "${output_folder}/vendor_boot.img"

  fastboot reboot recovery
  sleep 5 # before next prompt, so user does not see next msg well before it is ready
}

function flash_build() {
  echo "In the phone recovery menu (where you should be now - it might take a second), go to 'Apply Update' -> 'Apply from ADB', then hit enter:"
  read -r _ < /dev/tty

  # the most recently modified zip file ending in "UNOFFICIAL-{device name}" (OS image zip format)
  dumb_build=$(find "$output_folder" -maxdepth 1 -type f -iname "*UNOFFICIAL-${CODENAME}*.zip" \
      -exec stat --format '%Y %n' {} + 2>/dev/null \
      | sort -nr \
      | head -n 1 \
      | cut -d' ' -f2-)

  if [ -n "$dumb_build" ]; then
    echo "'Dirty flashing' the new dumb image..."
    adb sideload "$dumb_build"
  else
    echo "Build output zip file not found"
    exit 1
  fi
}

function ui_changes() {
  if [[ "${GRAYSCALE,,}" == "true" ]]; then
    echo "Turning your phone gray..."
    adb shell settings put secure accessibility_display_daltonizer_enabled 1
    adb shell settings put secure accessibility_display_daltonizer 0
  fi

  if [[ "${NIGHT_MODE,,}" == "true" ]]; then
    echo "Turning on night mode..."
    adb shell settings put secure night_display_activated 1
  fi

  if [[ "${BIG_FONT_DISPLAY,,}" == "true" ]]; then
    adb shell settings put system font_scale "$FONT_MULTIPLIER"
    echo "Increased system font size by ${FONT_MULTIPLIER}"

    PHYSICAL_DENSITY=$(adb shell wm density | grep -o 'Physical density: [0-9]*' | awk '{print $3}') # get only the native physical density, not the current override value
    BIG_DISPLAY=$(echo "$PHYSICAL_DENSITY * $DISPLAY_MULTIPLIER" | bc | cut -d'.' -f1) # apply multiplier, then truncate to make int
    adb shell wm density "$BIG_DISPLAY"
    echo "Increased display size by ${DISPLAY_MULTIPLIER}"
  fi

  if [[ "${DISABLE_ANIMATIONS,,}" == "true" ]]; then
    echo "Disabling animations..."
    adb shell settings put global window_animation_scale 0
    adb shell settings put global transition_animation_scale 0
    adb shell settings put global animator_duration_scale 0
  fi
}

function temp_store() {
  echo "Downloading latest Aurora Store APK from f-droid.org for TEMPORARY installation..."

  curl -s 'https://f-droid.org/en/packages/com.aurora.store/' \
    | grep -oP 'https://f-droid.org/repo/com\.aurora\.store[^"]+\.apk' \
    | head -1 \
    | xargs -I {} wget -O aurora-store-latest.apk {}

  echo "Temporarily installing the Aurora Store on your phone..."
  if [ -f "aurora-store-latest.apk" ]; then
    adb install "aurora-store-latest.apk"
  fi

  echo "Update any third party apps you have installed or add any apps you need (e.g. maps, secure messaging, notes, minimalist launcher)"
  echo "Warning: Some apps like Venmo, bank apps, and certain Google apps will not work."
  echo "Hit Enter when you are done installing/updating what you need:"
  read -r _ < /dev/tty

  # Clean up downloaded apk from pc
  echo "Deleting the Aurora Store .apk from your computer..."
  rm -f aurora-store-latest.apk

  echo "Uninstalling the Aurora Store app from your phone..."
  adb shell am force-stop com.aurora.store
  adb uninstall com.aurora.store
}

# disable these google ML services if they were not excluded from the build
function disable_google_services() {
  echo "Disabling some unnecessary Google programs on the phone..."

  if adb shell pm list packages | grep -q "com.google.android.as"; then
    adb shell pm disable-user --user 0 com.google.android.as # Android System Intelligence
  fi

  if adb shell pm list packages | grep -q "com.google.android.as.oss"; then
    adb shell pm disable-user --user 0 com.google.android.as.oss # Private Compute Services
  fi
}

main() {
  if [ ! -f "$script_in_here/config.sh" ]; then
    echo "No config.sh file found"
    exit 1
  fi

  source "$script_in_here/config.sh"
  
  if [ ! -d "$output_folder" ]; then
    echo "Error: build output directory not found"
    exit 1
  fi

  flash_recovery
  flash_build

  echo "Is the phone rebooted and unlocked now? Hit Enter when it is."
  read -r _ < /dev/tty
  
  ui_changes
  temp_store
  disable_google_services

  echo "Phone is dumber now!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi