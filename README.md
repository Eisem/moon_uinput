# MoonInput

[![Linux native CI](https://github.com/Eisem/moon_uinput/actions/workflows/ci.yml/badge.svg)](https://github.com/Eisem/moon_uinput/actions/workflows/ci.yml)

MoonInput is a native MoonBit library for the Linux Input Subsystem. It aims
to provide typed evdev event consumption and uinput virtual-device creation
without exposing Linux ABI details throughout application code.

The `eisem/mooninput` module implements typed evdev input, synchronous and
asynchronous reading, state recovery, exclusive device grabs, validated uinput
output, and a small CapsLock navigation remapper:

- MoonBit project and package structure;
- a small C shim that isolates `struct input_event` and ioctl ABI handling;
- typed event families, key codes, axes, key states, raw events, and decoded
  input events;
- evdev open, close, name, device ID, raw event reading, and typed event
  reading;
- safe `/dev/input/eventN` discovery with natural numeric ordering and
  per-device failure isolation;
- typed capability bitmaps and absolute-axis metadata;
- structured permission, missing-device, disconnection, ioctl, read, and
  unsupported-platform errors, including explicit closed-device and invalid
  path reporting;
- a blocking `EventStream`, device-listing, monitor, and capability examples;
- a pure MoonBit packetizer and a blocking packet stream aligned to
  `SYN_REPORT`;
- state snapshots and `Device::synced_packets()` recovery after `SYN_DROPPED`;
- opt-in `Device::grab()` / `ungrab()` with structured lifecycle errors;
- validated uinput device creation and cleanup;
- synchronized keyboard and mouse output, with every emitted event checked
  against the capabilities advertised during uinput creation;
- a CapsLock + H/J/K/L → Left/Down/Up/Right remapper with release and
  `SYN_DROPPED` reconciliation;
- async event, packet, and recovered-packet streams backed by a duplicated
  descriptor and no background reader task;
- hardware-independent tests and an opt-in real uinput/evdev round-trip test.

The C shims isolate Linux ABI and file-descriptor operations. Event decoding,
packetization, output policy, and remapping are implemented in MoonBit.

## Architecture

```text
/dev/input/eventX
        │
        ▼
thin C ABI shim
  open/read/ioctl
        │
        ▼
RawEvent (stable MoonBit fields)
        │
        ▼
typed decoder
        │
        ▼
InputEvent / EventStream or AsyncEventStream
```

MoonBit owns the public model, decoding, streaming abstraction, and error
mapping. C is restricted to system calls, Linux headers, and conversion from
the platform `struct input_event` into stable integer fields.

## Requirements and installation

- Linux with evdev enabled;
- MoonBit `0.1.20260920` or newer, with `moonbitlang/async@0.22.1`;
- a native C compiler and Linux input headers.

Clone the project and validate it with:

```bash
moon update
moon check --warn-list +unnecessary_annotation --deny-warn
moon test --target native --deny-warn
moon build --target native --deny-warn
```

The event model and decoder tests are hardware-independent. Live evdev access
requires Linux and a readable event device.

The package can be imported as `eisem/mooninput/src/evdev`,
`eisem/mooninput/src/event`, or `eisem/mooninput/src/uinput`. See the
[`examples`](examples) directory for runnable programs.

## Event monitor

List actual event nodes before selecting one:

```bash
moon run examples/list_devices
```

The listing reads directory entries instead of guessing a fixed event-number
range. Devices that disappear or cannot be opened remain in the output with a
structured reason; they do not stop later devices from being inspected. A
different input directory can be supplied for diagnostics:

```bash
moon run examples/list_devices -- /dev/input
```

Applications that need input frames instead of individual events can use
`Device::packets()`. It returns the events preceding each non-empty
`SYN_REPORT`, with the report timestamp attached to the packet. Empty frames
are skipped; other synchronization events are preserved in the packet for
higher layers to interpret. An I/O error propagates, and an incomplete packet
is never emitted.

For applications that maintain key or absolute-axis state, use
`Device::synced_packets()`. It discards the frame containing `SYN_DROPPED`,
queries pressed keys and current absolute-axis values at its terminating
`SYN_REPORT`, then returns `Recovered(state)` before resuming with later event
packets.

Choose a device explicitly and run:

```bash
moon run examples/monitor -- /dev/input/event4
```

The monitor opens the device read-only and does **not** call `EVIOCGRAB`.
Typical output is:

```text
KEY A PRESSED
SYN Report
KEY A RELEASED
SYN Report
```

Applications may opt into exclusive access with `device.grab()` and release it
with `device.ungrab()`. Closing the device also releases the kernel grab. A
grab redirects input away from other handlers, so it should be used only when
the application intentionally owns that device.

The current API can also be used directly:

```moonbit
let device = @evdev.Device::open("/dev/input/event4")
println(device.name())
let events = device.events()
for ;; {
  let event = events.next()
  println(event.to_repr())
}
```

## Device information and capabilities

Inspect the kernel-advertised event families, keys, axes, switches, LEDs, and
absolute-axis metadata without guessing from the device name:

```bash
moon run examples/device_info -- /dev/input/event4
```

Blocking `EventStream` and `DevicePacketStream` values share their device's
native handle. Closing that device invalidates both. Async streams duplicate
the descriptor and own the duplicate independently; close the stream and the
original device explicitly. They still compete for the same kernel event
queue, so do not read from both simultaneously. Concurrent calls to `next` on
one stream are unsupported.

## Async monitoring

The async API uses `moonbitlang/async/raw_fd` and reads the kernel's native
`input_event` size without hard-coding a 32/64-bit layout. It handles short
reads and awaits I/O without creating an unmanaged background task. On
cancellation, a partially filled record remains buffered for a later read.
`Device::async_synced_packets()` additionally performs the same
`SYN_DROPPED` state recovery as the blocking packet stream; keep the original
device open for its state-query ioctl.

```bash
moon run examples/async_monitor -- /dev/input/event4
```

The example prints complete frames and recovery snapshots and does not grab
the device. The async API is currently Linux-only; Windows native builds keep
the API surface but report `UnsupportedPlatform` on opening a stream.

## Permissions

MoonInput never invokes `sudo`, changes device permissions, or recommends
world-writable input nodes. If the process cannot read a selected evdev node,
`Device::open` raises `PermissionDenied(path=...)`.

Configure access using the security policy appropriate to the host, commonly
an input-device group or a narrowly scoped udev rule. Avoid `chmod 777`.

## Security and privacy

Raw keyboard devices can expose passwords, messages, and other sensitive
input. Applications should:

- require the user to choose a specific device;
- avoid logging or persisting events by default;
- never upload events without explicit informed consent;
- close devices promptly and handle disconnection errors.

The included monitor only prints events to its terminal. It does not persist,
transmit, or grab them.

## Linux compatibility

The native shim includes `<linux/input.h>` and asks the compiler for the
platform definitions of `struct input_event`, `EVIOCGNAME`, and `EVIOCGID`.
It does not hard-code a cross-architecture event structure layout. Event code
values follow Linux's stable userspace input ABI; unknown codes are retained
instead of rejected.

Non-Linux native builds compile a small fallback that reports
`UnsupportedPlatform`, allowing pure decoder tests to run on development
machines without pretending evdev is available.

## Relationship to libinput

MoonInput targets the lower-level Linux evdev/uinput interfaces. libinput adds
desktop input policy such as touchpad acceleration, gesture interpretation,
and palm detection. MoonInput does not replace libinput.

## Non-goals for v0.1

MoonInput does not aim to replace libinput, implement a desktop input stack,
provide Wayland or X11 APIs, become a complete remapping daemon or automation
framework, or support non-Linux operating systems.

## Creating virtual devices

`@uinput.VirtualDeviceBuilder` configures a virtual device name,
Linux identity and typed key/relative/absolute-axis capabilities. `validate()`
checks the configuration without requiring `/dev/uinput`; `create()` applies it
through the Linux uinput ioctls. Duplicate capabilities are ignored, and the
first setup for a repeated absolute axis wins. `VirtualDevice::close()` destroys
the kernel device and closes its descriptor; the native finalizer is a fallback.
`emit()` rejects unadvertised key, relative-axis, and absolute-axis codes
before calling `write`; only `SYN_REPORT` is accepted as a sync event.

Creating a device requires Linux and access to `/dev/uinput` (often via the
`uinput` kernel module and an appropriate group/udev policy). MoonInput does not
change permissions or load modules on the user's behalf.

The `examples/virtual_keyboard` program creates a virtual keyboard and sends
one A-key click. Its low-level `emit()` writes a single event; call `sync()` to
finish a frame. The key helpers emit a SYN_REPORT after each state change.
Running the example injects a real key into the desktop session, so only run it
when that behavior is intended.

The `examples/virtual_mouse` program creates a relative mouse, moves it, and
clicks its left button. `move_by(dx, dy)` groups both relative-axis events into
one frame, while button helpers end each press/release frame with SYN_REPORT.
Running it moves the host pointer and clicks in the active desktop session.

## CapsLock navigation remapper

```bash
moon run examples/remapper -- /dev/input/event4
```

Hold CapsLock while pressing H/J/K/L to emit Left/Down/Up/Right. Other keys
pass through; CapsLock itself is consumed. A key pressed before changing the
layer keeps its original output mapping until release. The remapper tracks
overlapping physical and mapped arrow-key holds, reconciles state after
`SYN_DROPPED`, and releases output keys on a handled error. It checks the
selected device's name and identity to avoid reading its own virtual output.

This program **grabs the specified input device** and creates a virtual
keyboard. On a real desktop, this affects keyboard input immediately. Choose
the source path explicitly, test from a recoverable terminal, and do not use
the remapper on a keyboard needed to regain access to that same terminal.
The example is a foreground process, not a daemon or startup service.

## Real uinput round-trip (opt-in)

The `examples/uinput_roundtrip` program creates a one-key virtual device,
discovers its evdev node through `UI_GET_SYSNAME`, and verifies both blocking
and async press/release readback. It neither injects a physical key nor grabs
a physical device. The test is not part of normal CI because access to
`/dev/uinput` varies by host. In an existing WSL2 Ubuntu installation where
`/dev/uinput` is root-only, run:

```bash
sudo env PATH="$HOME/.moon/bin:$PATH" \
  bash .ci/validate-uinput.sh "$PWD"
```

The script builds a temporary copy under `/tmp` as the source-directory owner,
runs only the short-lived test executable with root device access, and cleans
up its own temporary directory. It does not install Docker, change udev
permissions, or alter the project's Git history.

## Known limitations

- The async library's generic I/O and cancellation errors are propagated as
  generic `Error`; sync evdev methods provide structured `InputError` values.
- The remapper forwards key events only and uses a fixed CapsLock/H/J/K/L
  mapping; it is not a configurable desktop input daemon.
- Hardware readout and grabbing need Linux device access. A regular CI runner
  can still validate pure logic and compilation without `/dev/uinput`.

## Roadmap

1. Add an opt-in, configurable mapping format and safer interactive device
   selection to the remapper.
2. Extend typed output to switches, LEDs, and force feedback where supported.
3. Publish the GitHub repository and mooncakes.io module after final account
   and repository details are confirmed.

## License

MIT. See [LICENSE](LICENSE).
