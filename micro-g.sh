#!/bin/bash

function get_fdroid() {
curl -s 'https://f-droid.org/en/packages/org.fdroid.fdroid/' \
    | grep -o 'https://f-droid.org/repo/org.fdroid.fdroid[^"]*\.apk' \
    | head -n 1 \
    | xargs -r -I {} wget -O fdroid-latest.apk '{}'

    if [ -f "fdroid-latest.apk" ]; then
        adb install "fdroid-latest.apk"
    fi
}

function pull_up_qr() {
    url="https://repo.microg.org/fdroid/repo/"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url"
    elif command -v open >/dev/null 2>&1; then
        open "$url"
    else
        echo "No program to open QR code found." >&2
        return 1
    fi
}

function main() {
    get_fdroid
    pull_up_qr
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
