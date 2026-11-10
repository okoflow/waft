#!/bin/bash

set -euo pipefail

readonly DEFAULT_NAME='Waft Dev'
readonly KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
readonly EXPORT_PASSWORD='waft'
readonly USAGE='usage: scripts/signing.sh [name]'

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

is_installed() {
  local name=$1

  local identities
  identities=$(security find-identity -p codesigning "${KEYCHAIN}")

  [[ ${identities} == *"\"${name}\""* ]]
}

is_trusted() {
  local name=$1

  local identities
  identities=$(security find-identity -v -p codesigning "${KEYCHAIN}")

  [[ ${identities} == *"\"${name}\""* ]]
}

write_certificate_config() {
  local name=$1 path=$2

  cat >"${path}" <<CONFIG
[req]
distinguished_name = dn
x509_extensions    = ext
prompt             = no

[dn]
CN = ${name}

[ext]
basicConstraints = critical,CA:false
keyUsage         = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CONFIG
}

create_identity() {
  local name=$1

  local config="${WORK_DIR}/openssl.cnf"
  local key="${WORK_DIR}/key.pem"
  local certificate="${WORK_DIR}/certificate.pem"
  local identity="${WORK_DIR}/identity.p12"

  write_certificate_config "${name}" "${config}"

  if ! /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -config "${config}" -keyout "${key}" -out "${certificate}" 2>/dev/null; then
    die "couldn't create the certificate for \"${name}\""
  fi

  /usr/bin/openssl pkcs12 -export \
    -inkey "${key}" \
    -in "${certificate}" \
    -name "${name}" \
    -passout "pass:${EXPORT_PASSWORD}" \
    -out "${identity}"

  security import "${identity}" \
    -k "${KEYCHAIN}" \
    -P "${EXPORT_PASSWORD}" \
    -T /usr/bin/codesign >/dev/null

  echo "created \"${name}\" in ${KEYCHAIN}"
}

trust_identity() {
  local name=$1

  local certificate="${WORK_DIR}/trust.pem"

  security find-certificate -c "${name}" -p "${KEYCHAIN}" >"${certificate}"
  security add-trusted-cert -r trustRoot -p codeSign "${certificate}"
}

main() {
  [[ $# -le 1 ]] || usage

  local name=${1:-${DEFAULT_NAME}}

  if is_trusted "${name}"; then
    echo "\"${name}\" is already installed and trusted"

    return
  fi

  WORK_DIR=$(mktemp --directory)
  trap cleanup EXIT

  if ! is_installed "${name}"; then
    create_identity "${name}"
  fi

  trust_identity "${name}"

  is_trusted "${name}" || die "\"${name}\" is not trusted; run make signing again"

  echo "\"${name}\" is ready"
}

main "$@"
