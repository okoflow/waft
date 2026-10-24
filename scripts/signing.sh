#!/bin/bash
#
# Creates a self-signed code-signing identity in the login keychain and trusts
# it, so builds signed with it keep the permissions macOS granted them: Waft Dev
# for local builds by default, or the name given, such as Waft Release.

set -euo pipefail

readonly NAME="${1:-Waft Dev}"
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

has_identity() {
  local identities
  identities=$(security find-identity "$@" -p codesigning "${KEYCHAIN}")

  [[ ${identities} == *"\"${NAME}\""* ]]
}

write_certificate_config() {
  local path=$1

  cat >"${path}" <<CONFIG
[req]
distinguished_name = dn
x509_extensions    = ext
prompt             = no

[dn]
CN = ${NAME}

[ext]
basicConstraints = critical,CA:false
keyUsage         = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CONFIG
}

create_identity() {
  local config="${WORK_DIR}/openssl.cnf"
  local key="${WORK_DIR}/key.pem"
  local certificate="${WORK_DIR}/certificate.pem"
  local identity="${WORK_DIR}/identity.p12"

  write_certificate_config "${config}"

  if ! /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -config "${config}" -keyout "${key}" -out "${certificate}" 2>/dev/null; then
    die "couldn't create the certificate for \"${NAME}\""
  fi

  /usr/bin/openssl pkcs12 -export \
    -inkey "${key}" \
    -in "${certificate}" \
    -name "${NAME}" \
    -passout "pass:${EXPORT_PASSWORD}" \
    -out "${identity}"

  security import "${identity}" \
    -k "${KEYCHAIN}" \
    -P "${EXPORT_PASSWORD}" \
    -T /usr/bin/codesign >/dev/null

  echo "created \"${NAME}\" in ${KEYCHAIN}"
}

trust_identity() {
  local certificate="${WORK_DIR}/trust.pem"

  security find-certificate -c "${NAME}" -p "${KEYCHAIN}" >"${certificate}"
  security add-trusted-cert -r trustRoot -p codeSign "${certificate}"
}

main() {
  [[ $# -le 1 ]] || usage

  if has_identity -v; then
    echo "\"${NAME}\" is already installed and trusted"

    return
  fi

  WORK_DIR=$(mktemp --directory)
  trap cleanup EXIT

  if ! has_identity; then
    create_identity
  fi

  trust_identity

  has_identity -v || die "\"${NAME}\" is not trusted; run make signing again"

  echo "\"${NAME}\" is ready"
}

main "$@"
