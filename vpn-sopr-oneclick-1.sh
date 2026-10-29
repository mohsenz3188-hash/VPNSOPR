#!/usr/bin/env bash
# VPN SOPR single-command VPS installer.
# Upload this file and VPN-SOPR-Lite.zip to the root of the public
# https://github.com/mohsenz3188-hash/VPNSOPR repository (main branch).
# Then: curl -fsSL https://raw.githubusercontent.com/mohsenz3188-hash/VPNSOPR/main/vpn-sopr-oneclick.sh | sudo bash
set -Eeuo pipefail

readonly ZIP_URL='https://raw.githubusercontent.com/mohsenz3188-hash/VPNSOPR/main/VPN-SOPR-Lite.zip'
readonly ZIP_SHA256='2fead88a05c74e4354b504839ba7230b874a454ae7b9af422838b4748c0c13d4'

fail() { printf '[VPN SOPR] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Linux ]] || fail 'Linux VPS required.'
((EUID == 0)) || fail 'Run through sudo: curl ... | sudo bash'
command -v apt-get >/dev/null 2>&1 || fail 'This bootstrap supports Ubuntu/Debian (apt).'
command -v systemctl >/dev/null 2>&1 || fail 'systemd is required.'

printf '[VPN SOPR] Installing download and unpack tools...\n'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip

workdir="$(mktemp -d /tmp/vpn-sopr-bootstrap.XXXXXXXX)"
chmod 700 "$workdir"
cleanup() {
  if [[ -n "${workdir:-}" && -d "$workdir" && "$workdir" == /tmp/vpn-sopr-bootstrap.* ]]; then
    rm -rf -- "$workdir"
  fi
}
trap cleanup EXIT

printf '[VPN SOPR] Downloading customized VPN SOPR source...\n'
curl --fail --location --silent --show-error --retry 3 "$ZIP_URL" -o "$workdir/source.zip"
printf '%s  %s\n' "$ZIP_SHA256" "$workdir/source.zip" | sha256sum -c -
unzip -q "$workdir/source.zip" -d "$workdir"

source_dir="$workdir/vpn-sopr"
[[ -f "$source_dir/install-vpn-sopr.sh" && -f "$source_dir/go.mod" ]] || fail 'Invalid VPN SOPR archive.'
printf '[VPN SOPR] Starting VPS installer...\n'
bash "$source_dir/install-vpn-sopr.sh" --source-dir "$source_dir" "$@"
