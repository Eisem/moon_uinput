# MoonInput

MoonInput is a native MoonBit library for the Linux Input Subsystem. It aims
to provide typed evdev event consumption and uinput virtual-device creation
without exposing Linux ABI details throughout application code.

This repository currently implements typed evdev input, state recovery,
exclusive device grabs, a uinput virtual-device core, and virtual keyboard
output:

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
- synchronized key-down, key-up, and click output;
- synthetic decoder tests that require no input hardware.

Asynchronous reading and the remapper remain planned work.

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
InputEvent / EventStream
```

MoonBit owns the public model, decoding, streaming abstraction, and error
mapping. C is restricted to system calls, Linux headers, and conversion from
the platform `struct input_event` into stable integer fields.

## Requirements and installation

- Linux with evdev enabled;
- MoonBit `0.1.20260920` or newer;
- a native C compiler and Linux input headers.

Clone the project and validate it with:

```bash
moon check --warn-list +unnecessary_annotation
moon test --target native
moon build --target native
```

The event model and decoder tests are hardware-independent. Live evdev access
requires Linux and a readable event device.

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

`Device`, `EventStream`, and `DevicePacketStream` values share the same native
handle. Closing the device invalidates every stream derived from it; later
operations raise `DeviceClosed`. Calls on a shared handle must be serialized
by the application; concurrent reads or a read racing with `close` are not
supported.

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

`@mooninput/src/uinput.VirtualDeviceBuilder` configures a virtual device name,
Linux identity and typed key/relative/absolute-axis capabilities. `validate()`
checks the configuration without requiring `/dev/uinput`; `create()` applies it
through the Linux uinput ioctls. Duplicate capabilities are ignored, and the
first setup for a repeated absolute axis wins. `VirtualDevice::close()` destroys
the kernel device and closes its descriptor; the native finalizer is a fallback.

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

## Known limitations of the current slice

- event reading is blocking and synchronous;
- remapper is not implemented.

## Roadmap

1. P11–P12: remapper and release pipeline;
2. asynchronous event reading after the synchronous correctness baseline.

## License

MIT. See [LICENSE](LICENSE).
