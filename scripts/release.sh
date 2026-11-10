#!/bin/bash

set -euo pipefail

readonly PRODUCT='Waft'
readonly APP="build/${PRODUCT}.app"
readonly OUTPUT='build/release'
readonly REPOSITORY='okoflow/waft'
readonly WEBSITE='https://waft.okoflow.com'
readonly NOTARY_PROFILE='waft-notary'
readonly SPARKLE_TOOLS='.build/artifacts/sparkle/Sparkle/bin'
readonly CASK_TEMPLATE='Packaging/Homebrew/waft.rb'
readonly DEVELOPER_ID='Developer ID Application'
readonly RELEASE_IDENTITY='Waft Release'
readonly INFO_PLIST="Packaging/${PRODUCT}-Info.plist"
readonly PUBLISHED_APPCAST="https://github.com/${REPOSITORY}/releases/latest/download/appcast.xml"
readonly USAGE='usage: SIGNING_IDENTITY="Waft Release" scripts/release.sh release-notes.md'

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

is_developer_id() {
  [[ ${SIGNING_IDENTITY} == "${DEVELOPER_ID}"* ]]
}

app_version() {
  plutil -extract CFBundleShortVersionString raw "${INFO_PLIST}"
}

published_build() {
  curl --fail --silent --show-error --location "${PUBLISHED_APPCAST}" \
    | sed -n 's|.*<sparkle:version>\([0-9]*\)</sparkle:version>.*|\1|p' \
    | sort -n \
    | tail -n 1
}

check_build_number() {
  local build published
  build=$(plutil -extract CFBundleVersion raw "${INFO_PLIST}")
  published=$(published_build)

  [[ -n ${published} ]] || die "couldn't read the published build number from ${PUBLISHED_APPCAST}"
  ((build > published)) || die "CFBundleVersion ${build} must be above the published ${published}; Sparkle offers only a higher build"
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

  [[ -n ${SIGNING_IDENTITY:-} ]] || die 'set SIGNING_IDENTITY to Waft Release or your Developer ID Application identity'

  if [[ ${SIGNING_IDENTITY} != "${RELEASE_IDENTITY}" ]] && ! is_developer_id; then
    die "\"${SIGNING_IDENTITY}\" isn't ${RELEASE_IDENTITY} or a Developer ID Application identity"
  fi

  local identities
  identities=$(security find-identity -v -p codesigning)

  [[ ${identities} == *"\"${SIGNING_IDENTITY}\""* ]] || die "\"${SIGNING_IDENTITY}\" isn't in the keychain"

  if is_developer_id && ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null; then
    die "no notarytool profile \"${NOTARY_PROFILE}\": run xcrun notarytool store-credentials ${NOTARY_PROFILE}"
  fi

  local sparkle_key expected_key
  sparkle_key=$("${SPARKLE_TOOLS}/generate_keys" -p) || die 'no Sparkle signing key in the login keychain'
  expected_key=$(plutil -extract SUPublicEDKey raw "${INFO_PLIST}")

  [[ ${sparkle_key} == "${expected_key}" ]] || die "the Sparkle key in the login keychain isn't the SUPublicEDKey of ${INFO_PLIST}"
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

  if ! is_developer_id; then
    codesign --force --sign "${SIGNING_IDENTITY}" "${image}"

    return
  fi

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

  if grep --quiet -e '"VERSION"' -e '"SHA256"' "${OUTPUT}/waft.rb"; then
    die "${CASK_TEMPLATE} no longer has the VERSION and SHA256 placeholders this script fills"
  fi
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
  check_build_number
  check_prerequisites

  WORK_DIR=$(mktemp --directory)
  trap cleanup EXIT

  rm -rf -- "${OUTPUT:?}"
  mkdir -p "${OUTPUT}"

  scripts/bundle.sh release
  codesign --verify --deep --strict "${APP}"

  if is_developer_id; then
    notarize_app
  fi

  make_disk_image "${image}"
  make_appcast "${version}" "${notes}"
  write_cask "${version}" "${image}"
  print_next_steps "${version}" "${commit}" "${image}" "${notes}"
}

main "$@"
