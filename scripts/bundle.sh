#!/bin/bash

set -euo pipefail

readonly PRODUCT='Waft'
readonly APP="build/${PRODUCT}.app"
readonly CONTENTS="${APP}/Contents"
readonly RESOURCES="${CONTENTS}/Resources"
readonly FRAMEWORK="${CONTENTS}/Frameworks/Sparkle.framework"
readonly ENTITLEMENTS="Packaging/${PRODUCT}.entitlements"
readonly IDENTITY="${SIGNING_IDENTITY:-Waft Dev}"
readonly RULE='================================================================================'
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

warn() {
  printf 'warning: %s\n' "$@" >&2
}

has_identity() {
  local identities
  identities=$(security find-identity -v -p codesigning)

  [[ ${identities} == *"\"${IDENTITY}\""* ]]
}

print_licenses() {
  local path=$1

  local files
  files=$(find "${path}" -maxdepth 1 -type f \( -name 'LICENSE*' -o -name 'NOTICE*' \) | sort)

  [[ -n ${files} ]] || die "${path} has no license file"

  local file

  while IFS= read -r file; do
    echo
    cat "${file}"
  done <<<"${files}"
}

print_acknowledgments() {
  local packages
  packages=$(
    swift package show-dependencies --format json \
      | jq --raw-output '.dependencies[] | [.name, .version, (.url | sub("\\.git$"; "")), .path] | @tsv'
  )

  echo "${PRODUCT} includes the following third-party software."

  local name version url path

  while IFS=$'\t' read -r name version url path; do
    printf '\n%s\n%s %s\n%s\n%s\n' "${RULE}" "${name}" "${version}" "${url}" "${RULE}"
    print_licenses "${path}"
  done <<<"${packages}"
}

assemble_app() {
  local configuration=$1 binary_dir=$2

  rm -rf -- "${APP:?}"
  mkdir -p "${CONTENTS}/MacOS" "${CONTENTS}/Frameworks" "${RESOURCES}"

  cp "${binary_dir}/${PRODUCT}" "${CONTENTS}/MacOS/${PRODUCT}"
  cp "Packaging/${PRODUCT}-Info.plist" "${CONTENTS}/Info.plist"
  cp "Packaging/${PRODUCT}.icns" "${RESOURCES}/${PRODUCT}.icns"
  cp -R Packaging/Localizations/*.lproj "${RESOURCES}/"
  cp Packaging/Sounds/*.aiff "${RESOURCES}/"
  cp LICENSE "${RESOURCES}/"
  print_acknowledgments >"${RESOURCES}/ACKNOWLEDGMENTS"

  ditto "${binary_dir}/Sparkle.framework" "${FRAMEWORK}"
  rm -rf -- "${FRAMEWORK}/Versions/B/XPCServices" "${FRAMEWORK}/XPCServices"
  install_name_tool -add_rpath @executable_path/../Frameworks "${CONTENTS}/MacOS/${PRODUCT}"

  if [[ ${configuration} == debug ]]; then
    plutil -remove SUFeedURL "${CONTENTS}/Info.plist"
  fi
}

sign() {
  local identity=$1
  shift

  local -a options=(--force --sign "${identity}")

  if [[ ${identity} == 'Developer ID Application'* ]]; then
    options+=(--options runtime --timestamp)
  fi

  codesign "${options[@]}" "$@"
}

sign_app() {
  local identity=${IDENTITY}

  if ! has_identity; then
    identity='-'

    warn "\"${IDENTITY}\" isn't installed, so ${APP} is signed ad hoc and rebuilds lose its permissions" \
      'run make signing once to keep them'
  fi

  sign "${identity}" "${FRAMEWORK}/Versions/B/Autoupdate"
  sign "${identity}" "${FRAMEWORK}/Versions/B/Updater.app"
  sign "${identity}" "${FRAMEWORK}"
  sign "${identity}" --entitlements "${ENTITLEMENTS}" "${APP}"

  echo "signed ${APP} with \"${identity}\"" >&2
}

main() {
  [[ $# -le 1 ]] || usage

  local configuration=${1:-debug}

  [[ ${configuration} == debug || ${configuration} == release ]] || usage

  cd "$(dirname "$0")/.."

  if [[ -n ${SIGNING_IDENTITY:-} ]] && ! has_identity; then
    die "\"${IDENTITY}\" isn't in the keychain"
  fi

  swift build --configuration "${configuration}" --product "${PRODUCT}" >&2

  local binary_dir
  binary_dir=$(swift build --configuration "${configuration}" --show-bin-path)

  assemble_app "${configuration}" "${binary_dir}"
  sign_app

  echo "${APP}"
}

main "$@"
