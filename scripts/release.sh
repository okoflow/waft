#!/bin/bash
#
# Builds, notarizes, and packages a release of Waft from origin/main: the
# disk image, the signed appcast, and the Homebrew cask, in build/release.

set -euo pipefail

readonly PRODUCT='Waft'
readonly APP="build/${PRODUCT}.app"
readonly OUTPUT='build/release'
readonly REPOSITORY='okoflow/waft'
readonly WEBSITE='https://waft.okoflow.com'
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-waft-notary}"
readonly SPARKLE_TOOLS='.build/artifacts/sparkle/Sparkle/bin'
readonly CASK_TEMPLATE='Packaging/Homebrew/waft.rb'
readonly USAGE='usage: SIGNING_IDENTITY="Developer ID Application: …" scripts/release.sh release-notes.md'

WORK_DIR=''

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

cleanup() {
  if [[ -n ${WORK_DIR} ]]; then
    rm -rf -- "${WORK_DIR}"
  fi
}

app_version() {
  plutil -extract CFBundleShortVersionString raw "Packaging/${PRODUCT}-Info.plist"
}

check_tree() {
  local tag=$1 commit=$2

  git fetch --quiet origin main

  local changes main_commit tags
  changes=$(git status --porcelain)
  main_commit=$(git rev-parse origin/main)
  tags=$(git ls-remote --tags origin "refs/tags/${tag}")

  [[ -z ${changes} ]] || die 'commit or remove these changes first:' "${changes}"
  [[ ${commit} == "${main_commit}" ]] || die "HEAD isn't origin/main; check out the latest main first"
  [[ -z ${tags} ]] || die "${tag} already exists on origin; raise the version first"
}

check_prerequisites() {
  swift package resolve >&2

  [[ ${SIGNING_IDENTITY:-} == 'Developer ID Application'* ]] \
    || die 'set SIGNING_IDENTITY to your Developer ID Application identity'

  if ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null; then
    die "no notarytool profile \"${NOTARY_PROFILE}\": run xcrun notarytool store-credentials ${NOTARY_PROFILE}"
  fi

  if ! "${SPARKLE_TOOLS}/generate_keys" -p >/dev/null; then
    die 'no Sparkle signing key in the login keychain'
  fi
}

notarize() {
  local path=$1

  xcrun notarytool submit --keychain-profile "${NOTARY_PROFILE}" --wait "${path}"
}

notarize_app() {
  local archive="${WORK_DIR}/${PRODUCT}.zip"

  ditto -c -k --keepParent "${APP}" "${archive}"
  notarize "${archive}"
  xcrun stapler staple "${APP}"
}

make_disk_image() {
  local image=$1
  local staging="${WORK_DIR}/image"

  mkdir -p "${staging}"
  ditto "${APP}" "${staging}/${PRODUCT}.app"
  ln -s /Applications "${staging}/Applications"

  hdiutil create -volname "${PRODUCT}" -srcfolder "${staging}" -format UDZO -ov "${image}" >/dev/null
  codesign --force --timestamp --sign "${SIGNING_IDENTITY}" "${image}"
  notarize "${image}"
  xcrun stapler staple "${image}"
  spctl --assess --type open --context context:primary-signature "${image}"
}

make_appcast() {
  local version=$1 notes=$2

  cp "${notes}" "${OUTPUT}/${PRODUCT}-${version}.md"

  "${SPARKLE_TOOLS}/generate_appcast" \
    --download-url-prefix "https://github.com/${REPOSITORY}/releases/download/v${version}/" \
    --full-release-notes-url "https://github.com/${REPOSITORY}/releases/tag/v${version}" \
    --link "${WEBSITE}" \
    --embed-release-notes \
    "${OUTPUT}"
}

write_cask() {
  local version=$1 image=$2

  local checksum
  checksum=$(shasum --algorithm 256 "${image}" | cut -d ' ' -f 1)

  sed -e "s/VERSION/${version}/" -e "s/SHA256/${checksum}/" "${CASK_TEMPLATE}" >"${OUTPUT}/waft.rb"
}

print_next_steps() {
  local version=$1 commit=$2 image=$3 notes=$4

  cat <<STEPS
Release artifacts are in ${OUTPUT}. To publish v${version}:

  gh release create v${version} ${image} ${OUTPUT}/appcast.xml --target ${commit} --title v${version} --notes-file ${notes}
  cp ${OUTPUT}/waft.rb <okoflow/homebrew-tap>/Casks/waft.rb

Then commit and push the cask in the tap.
STEPS
}

main() {
  [[ $# -eq 1 ]] || usage

  cd "$(dirname "$0")/.."

  local notes=$1
  [[ -f ${notes} ]] || die "no release notes at \"${notes}\""

  local version commit
  version=$(app_version)
  commit=$(git rev-parse HEAD)

  local image="${OUTPUT}/${PRODUCT}-${version}.dmg"

  check_tree "v${version}" "${commit}"
  check_prerequisites

  WORK_DIR=$(mktemp -d)
  trap cleanup EXIT

  rm -rf -- "${OUTPUT:?}"
  mkdir -p "${OUTPUT}"

  scripts/bundle.sh release
  notarize_app
  make_disk_image "${image}"
  make_appcast "${version}" "${notes}"
  write_cask "${version}" "${image}"
  print_next_steps "${version}" "${commit}" "${image}" "${notes}"
}

main "$@"
