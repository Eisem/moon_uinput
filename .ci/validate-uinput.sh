#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:?usage: validate-uinput.sh SOURCE_DIR}"
validation_dir="$(mktemp -d /tmp/mooninput-uinput.XXXXXX)"
source_owner="$(stat -c %U "$source_dir")"
source_home="$(getent passwd "$source_owner" | cut -d: -f6)"

cleanup() {
  case "$validation_dir" in
    /tmp/mooninput-uinput.*) rm -rf -- "$validation_dir" ;;
    *) echo "refusing cleanup: $validation_dir" >&2 ;;
  esac
}
trap cleanup EXIT

cd "$source_dir"
tar --exclude=./_build --exclude=./.mooncakes --exclude=./.repos \
  --exclude=./.git --exclude=./.git-codex-hold -cf - . \
  | tar -xf - -C "$validation_dir"

cd "$validation_dir"
chown -R "$source_owner" "$validation_dir"
runuser -u "$source_owner" -- env \
  PATH="$source_home/.moon/bin:$PATH" \
  moon build examples/uinput_roundtrip --target native --deny-warn
roundtrip="$validation_dir/_build/native/debug/build/examples/uinput_roundtrip/uinput_roundtrip.exe"
output="$(timeout 20s "$roundtrip")"
echo "$output"
grep -Fx 'UINPUT_ROUNDTRIP_OK' <<<"$output" >/dev/null
