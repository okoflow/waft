#!/bin/bash
set -euo pipefail

readonly PRODUCT='Waft'
readonly APP="build/${PRODUCT}.app"
readonly RESOURCES="${APP}/Contents/Resources"
readonly FRAMEWORK="${APP}/Contents/Frameworks/Sparkle.framework"
readonly ENTITLEMENTS="Packaging/${PRODUCT}.entitlements"
readonly IDENTITY="${SIGNING_IDENTITY:-Waft Dev}"
readonly USAGE='usage: scripts/bundle.sh [debug|release]'

usage() {
  echo "${USAGE}" >&2

  exit 2
}

die() {
  local message
  printf -v message '%s\n' "$@"

  printf 'error: %s' "${message}" >&2

  exit 1
}

build_binary() {
  local configuration=$1

  swift build --configuration "${configuration}" --product "${PRODUCT}" >&2

  swift build --configuration "${configuration}" --show-bin-path
}

assemble_app() {
  local configuration=$1 binary_dir=$2

  rm -rf "${APP}"
  mkdir -p "${APP}/Contents/MacOS" "${RESOURCES}" "${APP}/Contents/Frameworks"

  cp "${binary_dir}/${PRODUCT}" "${APP}/Contents/MacOS/${PRODUCT}"
  cp "Packaging/${PRODUCT}-Info.plist" "${APP}/Contents/Info.plist"
  cp "Packaging/${PRODUCT}.icns" "${RESOURCES}/${PRODUCT}.icns"
  cp -R Packaging/Localizations/*.lproj "${RESOURCES}/"
  ditto "${binary_dir}/Sparkle.framework" "${FRAMEWORK}"
  rm -rf "${FRAMEWORK}/Versions/B/XPCServices" "${FRAMEWORK}/XPCServices"
  install_name_tool -add_rpath @executable_path/../Frameworks "${APP}/Contents/MacOS/${PRODUCT}"

  if [[ ${configuration} == debug ]]; then
    plutil -remove SUFeedURL "${APP}/Contents/Info.plist"
  fi
}

has_identity() {
  security find-identity -v -p codesigning | grep -qF "\"${IDENTITY}\""
}

sign() {
  local identity=$1
  shift

  if [[ ${identity} == 'Developer ID Application'* ]]; then
    codesign --force --options runtime --timestamp --sign "${identity}" "$@"
  else
    codesign --force --sign "${identity}" "$@"
  fi
}

sign_app() {
  local identity=${IDENTITY}

  if ! has_identity; then
    identity='-'

    echo "warning: \"${IDENTITY}\" isn't installed, so ${APP} is signed ad hoc and rebuilds lose its permissions" >&2
    echo "warning: run make signing once to keep them" >&2
  fi

  sign "${identity}" "${FRAMEWORK}/Versions/B/Autoupdate"
  sign "${identity}" "${FRAMEWORK}/Versions/B/Updater.app"
  sign "${identity}" "${FRAMEWORK}"
  sign "${identity}" --entitlements "${ENTITLEMENTS}" "${APP}"

  echo "signed ${APP} with \"${identity}\"" >&2
}

main() {
  [[ $# -le 1 ]] || usage

  cd "$(dirname "$0")/.."

  local configuration=${1:-debug}
  [[ ${configuration} == debug || ${configuration} == release ]] || usage

  [[ -z ${SIGNING_IDENTITY:-} ]] || has_identity || die "\"${IDENTITY}\" isn't in the keychain"

  local binary_dir
  binary_dir=$(build_binary "${configuration}")

  assemble_app "${configuration}" "${binary_dir}"
  sign_app

  echo "${APP}"
}

main "$@"
