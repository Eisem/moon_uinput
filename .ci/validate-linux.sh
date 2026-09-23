#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.moon/bin:$PATH"

source_dir="${1:?usage: validate-linux.sh SOURCE_DIR}"
validation_dir="$(mktemp -d /tmp/mooninput-check.XXXXXX)"

cleanup() {
  case "$validation_dir" in
    /tmp/mooninput-check.*) rm -rf -- "$validation_dir" ;;
    *) echo "refusing cleanup: $validation_dir" >&2 ;;
  esac
}
trap cleanup EXIT

cd "$source_dir"
tar --exclude=./_build --exclude=./.git -cf - . \
  | tar -xf - -C "$validation_dir"

cd "$validation_dir"
echo "validation_dir=$validation_dir"
moon version --all
moon update
gcc -std=gnu11 -Wall -Wextra -Werror \
  -I"$HOME/.moon/include" \
  -c src/evdev/linux_input.c \
  -o "$validation_dir/linux_input.strict.o"
gcc -std=gnu11 -Wall -Wextra -Werror \
  -I"$HOME/.moon/include" \
  -c src/uinput/linux_uinput.c \
  -o "$validation_dir/linux_uinput.strict.o"
moon check --warn-list +unnecessary_annotation --deny-warn
moon test --target native --deny-warn -v
moon build --target native --deny-warn
moon info --target native
monitor_output="$(
  moon run examples/monitor -- /dev/input/mooninput-does-not-exist
)"
echo "$monitor_output"
grep -F "Input device not found" <<<"$monitor_output" >/dev/null
listing_output="$(
  moon run examples/list_devices -- /dev/input/mooninput-does-not-exist
)"
echo "$listing_output"
grep -F "Discovering input devices" <<<"$listing_output" >/dev/null
echo "LINUX_VALIDATION_OK"
