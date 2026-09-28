# Changelog

## Unreleased

## 0.1.0 - 2026-09-28

- Typed Linux evdev events, device discovery, capabilities, absolute axes,
  packetization, and state recovery after dropped frames.
- Structured errors, read-only monitoring, and optional exclusive grabs.
- Validated uinput virtual-device builder with keyboard and mouse helpers.
- Native C shims limited to Linux ABI and file-descriptor operations.
- Added async event, packet, and `SYN_DROPPED`-aware readers with independent
  descriptor ownership, cancellation-safe direct reads, and structured device
  errors.
- Added the CapsLock + H/J/K/L keyboard remapper with explicit source grab,
  output-key reconciliation, and feedback-loop avoidance.
- Added output capability checks so virtual devices cannot emit codes they did
  not advertise to the kernel.
- Added a real, opt-in uinput-to-evdev round-trip validation for both blocking
  and async readers in Linux/WSL2.
- Expanded cross-platform tests and documented the publication workflow.
