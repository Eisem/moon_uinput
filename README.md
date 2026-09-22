# MoonInput

MoonInput is a native MoonBit library for the Linux Input Subsystem. It aims
to provide typed evdev event consumption and uinput virtual-device creation
without exposing Linux ABI details throughout application code.

This repository currently implements the first delivery slice, **P0–P3**:

- MoonBit project and package structure;
- a small C shim that isolates `struct input_event` and ioctl ABI handling;
- typed event families, key codes, axes, key states, raw events, and decoded
  input events;
- evdev open, close, name, device ID, raw event reading, and typed event
  reading;
- structured permission, missing-device, disconnection, ioctl, read, and
  unsupported-platform errors, including explicit closed-device and invalid
  path reporting;
- a blocking `EventStream` and monitor example;
- synthetic decoder tests that require no input hardware.

Capabilities, packetization, `SYN_DROPPED` recovery, grabbing, asynchronous
reading, and uinput are later milestones and are not claimed by this slice.

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

`Device` and `EventStream` values share the same native handle. Closing one
invalidates every value derived from that device; later operations raise
`DeviceClosed`. Calls on a shared handle must be serialized by the application;
concurrent reads or a read racing with `close` are not supported.

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

## Known limitations of the P0–P3 slice

- event reading is blocking and synchronous;
- capabilities and absolute-axis metadata are not queried yet;
- events are not yet grouped at `SYN_REPORT` boundaries;
- `SYN_DROPPED` is decoded but state recovery is not yet implemented;
- `EVIOCGRAB` and uinput virtual devices are not implemented.

## Roadmap

1. P4: capability bitmaps and absolute-axis metadata;
2. P5: event packetization at `SYN_REPORT`;
3. P6: `SYN_DROPPED` state recovery;
4. P7: explicit grab/ungrab;
5. P8–P10: uinput keyboard, mouse, and remapper pipeline;
6. asynchronous event reading after the synchronous correctness baseline.

## License

MIT. See [LICENSE](LICENSE).
