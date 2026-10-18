#!/bin/bash
#
# Checks every translation in Packaging/Localizations against the strings that
# make build extracts from the code, or rewrites the English table from them.

set -euo pipefail

readonly LOCALIZATIONS='Packaging/Localizations'
readonly SOURCE_TABLE="${LOCALIZATIONS}/en.lproj/Localizable.strings"
readonly PLIST_KEY='NSMicrophoneUsageDescription'
readonly USAGE='usage: STRINGS_DIR=<extracted strings> scripts/strings.sh [check|update]'
readonly SPECIFIERS='def specifiers:
  [scan("%(?:[0-9]+\\$)?[-+ 0#]*[0-9]*(?:\\.[0-9]+)?(?:hh|h|ll|l|q|z|t|j|L)?[@dDiuUxXoOfeEgGcCsSpaAF%]")]
  | map(sub("^%[0-9]+\\$"; "%")) | map(select(. != "%%")) | sort;'

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

code_keys() {
  local output=$1

  [[ -d ${STRINGS_DIR} ]] || die "no strings in ${STRINGS_DIR}: run make build"

  local root sources
  root=$(pwd -P)
  sources=$(find Sources -name '*.swift')

  local file data source

  : >"${output}.unsorted"

  while IFS= read -r file; do
    data="${STRINGS_DIR}/$(basename "${file}" .swift).stringsdata"

    [[ -f ${data} ]] || die "${file} has no extracted strings: run make build"

    source=$(jq --raw-output '.source' "${data}")

    [[ ${source} == "${root}/${file}" ]] || die "${data} belongs to ${source}: run make build"

    jq '.tables.Localizable[]?.key | select(. != "%@")' "${data}" >>"${output}.unsorted"
  done <<<"${sources}"

  LC_ALL=C sort -u "${output}.unsorted" >"${output}"
}

table_keys() {
  local table=$1 output=$2

  plutil -convert json -o "${output}.json" "${table}"
  jq 'keys[]' "${output}.json" >"${output}.unsorted"
  LC_ALL=C sort -u "${output}.unsorted" >"${output}"
}

check_keys() {
  local table=$1 expected=$2 hint=$3

  local actual="${WORK_DIR}/actual"

  plutil -lint -s "${table}" || die "${table} isn't a valid strings file"
  table_keys "${table}" "${actual}"

  local missing extra
  missing=$(LC_ALL=C comm -23 "${expected}" "${actual}")
  extra=$(LC_ALL=C comm -13 "${expected}" "${actual}")

  [[ -z ${missing} ]] || die "${table} is missing keys${hint}:" "${missing}"
  [[ -z ${extra} ]] || die "${table} has keys the code no longer uses${hint}:" "${extra}"
}

check_specifiers() {
  local table=$1

  local json="${WORK_DIR}/table.json"

  plutil -convert json -o "${json}" "${table}"

  local mismatched
  mismatched=$(jq --raw-output "${SPECIFIERS} to_entries[] | select((.key | specifiers) != (.value | specifiers)) | .key" "${json}")

  [[ -z ${mismatched} ]] || die "${table} changes the placeholders of:" "${mismatched}"
}

check_plist_strings() {
  local table="$1/InfoPlist.strings"

  [[ -f ${table} ]] || die "${table} is missing"
  plutil -lint -s "${table}" || die "${table} isn't a valid strings file"
  plutil -extract "${PLIST_KEY}" raw -o /dev/null "${table}" || die "${table} has no ${PLIST_KEY}"
}

check() {
  local expected="${WORK_DIR}/expected"
  local languages=0

  code_keys "${expected}"
  check_keys "${SOURCE_TABLE}" "${expected}" ' (run make strings-update)'

  local directory

  for directory in "${LOCALIZATIONS}"/*.lproj; do
    languages=$((languages + 1))

    if [[ ${directory} == "$(dirname "${SOURCE_TABLE}")" ]]; then
      continue
    fi

    check_keys "${directory}/Localizable.strings" "${expected}" ''
    check_specifiers "${directory}/Localizable.strings"
    check_plist_strings "${directory}"
  done

  local count
  count=$(wc -l <"${expected}")

  echo "strings: ${count// /} keys in ${languages} languages"
}

update() {
  local keys="${WORK_DIR}/keys"

  code_keys "${keys}"
  mkdir -p "$(dirname "${SOURCE_TABLE}")"

  local key

  while IFS= read -r key; do
    printf '%s = %s;\n' "${key}" "${key}"
  done <"${keys}" >"${SOURCE_TABLE}"

  echo "${SOURCE_TABLE}"
}

main() {
  [[ $# -le 1 ]] || usage
  [[ -n ${STRINGS_DIR:-} ]] || usage

  cd "$(dirname "$0")/.."

  WORK_DIR=$(mktemp -d)
  trap cleanup EXIT

  case ${1:-check} in
    check) check ;;
    update) update ;;
    *) usage ;;
  esac
}

main "$@"
