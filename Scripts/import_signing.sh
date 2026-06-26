#!/usr/bin/env bash
set -euo pipefail

: "${CERTIFICATE_P12_BASE64:?CERTIFICATE_P12_BASE64 ausente}"
: "${CERTIFICATE_PASSWORD:?CERTIFICATE_PASSWORD ausente}"
: "${KEYCHAIN_PASSWORD:?KEYCHAIN_PASSWORD ausente}"
: "${APP_PROFILE_BASE64:?APP_PROFILE_BASE64 ausente}"
: "${WIDGET_PROFILE_BASE64:?WIDGET_PROFILE_BASE64 ausente}"

KEYCHAIN_PATH="$RUNNER_TEMP/cortex-signing.keychain-db"
CERT_PATH="$RUNNER_TEMP/certificate.p12"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"

echo "$CERTIFICATE_P12_BASE64" | base64 --decode > "$CERT_PATH"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -P "$CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security list-keychain -d user -s "$KEYCHAIN_PATH" login.keychain-db
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

install_profile() {
  local base64_value="$1"
  local label="$2"
  local profile_path="$RUNNER_TEMP/$label.mobileprovision"
  local plist_path="$RUNNER_TEMP/$label.plist"
  echo "$base64_value" | base64 --decode > "$profile_path"
  security cms -D -i "$profile_path" > "$plist_path"
  local uuid name
  uuid=$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$plist_path")
  name=$(/usr/libexec/PlistBuddy -c 'Print :Name' "$plist_path")
  cp "$profile_path" "$PROFILE_DIR/$uuid.mobileprovision"
  printf '%s' "$name"
}

APP_NAME="$(install_profile "$APP_PROFILE_BASE64" app)"
WIDGET_NAME="$(install_profile "$WIDGET_PROFILE_BASE64" widget)"

echo "app_profile_name=$APP_NAME" >> "$GITHUB_OUTPUT"
echo "widget_profile_name=$WIDGET_NAME" >> "$GITHUB_OUTPUT"
