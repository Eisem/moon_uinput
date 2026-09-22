///|
/// Linux absolute-axis metadata returned by `EVIOCGABS`.
pub(all) struct AbsoluteAxisInfo {
  value : Int
  minimum : Int
  maximum : Int
  fuzz : Int
  flat : Int
  resolution : Int
} derive(Debug, Eq)

///|
pub extend AbsoluteAxisInfo with Debug::{to_repr}

///|
pub extend AbsoluteAxisInfo with Eq::{equal, not_equal}

///|
/// One supported absolute axis and its optional runtime metadata.
pub(all) struct AbsoluteAxisCapability {
  axis : @codes.AbsoluteAxis
  info : AbsoluteAxisInfo?
} derive(Debug, Eq)

///|
pub extend AbsoluteAxisCapability with Debug::{to_repr}

///|
pub extend AbsoluteAxisCapability with Eq::{equal, not_equal}

///|
/// Typed capabilities advertised by an evdev device.
pub(all) struct DeviceCapabilities {
  event_types : Array[@codes.EventType]
  keys : Array[@codes.KeyCode]
  relative_axes : Array[@codes.RelativeAxis]
  absolute_axes : Array[AbsoluteAxisCapability]
  switches : Array[@codes.SwitchCode]
  leds : Array[@codes.LedCode]
} derive(Debug, Eq)

///|
pub extend DeviceCapabilities with Debug::{to_repr}

///|
pub extend DeviceCapabilities with Eq::{equal, not_equal}

///|
/// Return an empty capability set.
pub fn DeviceCapabilities::empty() -> DeviceCapabilities {
  decode_capability_bitmaps(b"", b"", b"", b"", b"", b"")
}

///|
/// Test whether this device advertises an event family.
pub fn DeviceCapabilities::supports_event(
  self : DeviceCapabilities,
  event_type : @codes.EventType,
) -> Bool {
  self.event_types.contains(event_type)
}

///|
/// Test whether this device advertises a key or button code.
pub fn DeviceCapabilities::supports_key(
  self : DeviceCapabilities,
  key : @codes.KeyCode,
) -> Bool {
  self.keys.contains(key)
}

///|
/// Test whether this device advertises a relative axis.
pub fn DeviceCapabilities::supports_relative_axis(
  self : DeviceCapabilities,
  axis : @codes.RelativeAxis,
) -> Bool {
  self.relative_axes.contains(axis)
}

///|
/// Test whether this device advertises an absolute axis.
pub fn DeviceCapabilities::supports_absolute_axis(
  self : DeviceCapabilities,
  axis : @codes.AbsoluteAxis,
) -> Bool {
  self.absolute_axis(axis) is Some(_)
}

///|
/// Return the advertised entry for an absolute axis.
pub fn DeviceCapabilities::absolute_axis(
  self : DeviceCapabilities,
  axis : @codes.AbsoluteAxis,
) -> AbsoluteAxisCapability? {
  for entry in self.absolute_axes {
    if entry.axis == axis {
      return Some(entry)
    }
  }
  None
}

///|
/// Test whether this device advertises a switch code.
pub fn DeviceCapabilities::supports_switch(
  self : DeviceCapabilities,
  switch : @codes.SwitchCode,
) -> Bool {
  self.switches.contains(switch)
}

///|
/// Test whether this device advertises an LED code.
pub fn DeviceCapabilities::supports_led(
  self : DeviceCapabilities,
  led : @codes.LedCode,
) -> Bool {
  self.leds.contains(led)
}

///|
fn bitmap_contains(bitmap : Bytes, code : Int) -> Bool {
  if code < 0 {
    return false
  }
  let byte_index = code / 8
  if byte_index >= bitmap.length() {
    return false
  }
  let mask = 1 << (code % 8)
  (bitmap[byte_index].to_int() & mask) != 0
}

///|
fn decode_event_types(bitmap : Bytes) -> Array[@codes.EventType] {
  let result : Array[@codes.EventType] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push(@codes.EventType::from_linux(code))
    }
  }
  result
}

///|
fn decode_keys(bitmap : Bytes) -> Array[@codes.KeyCode] {
  let result : Array[@codes.KeyCode] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push(@codes.KeyCode::from_linux(code))
    }
  }
  result
}

///|
fn decode_relative_axes(bitmap : Bytes) -> Array[@codes.RelativeAxis] {
  let result : Array[@codes.RelativeAxis] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push(@codes.RelativeAxis::from_linux(code))
    }
  }
  result
}

///|
fn decode_absolute_axes(bitmap : Bytes) -> Array[AbsoluteAxisCapability] {
  let result : Array[AbsoluteAxisCapability] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push({ axis: @codes.AbsoluteAxis::from_linux(code), info: None, })
    }
  }
  result
}

///|
fn decode_switches(bitmap : Bytes) -> Array[@codes.SwitchCode] {
  let result : Array[@codes.SwitchCode] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push(@codes.SwitchCode::from_linux(code))
    }
  }
  result
}

///|
fn decode_leds(bitmap : Bytes) -> Array[@codes.LedCode] {
  let result : Array[@codes.LedCode] = []
  for code in 0..<(bitmap.length() * 8) {
    if bitmap_contains(bitmap, code) {
      result.push(@codes.LedCode::from_linux(code))
    }
  }
  result
}

///|
fn decode_capability_bitmaps(
  event_types : Bytes,
  keys : Bytes,
  relative_axes : Bytes,
  absolute_axes : Bytes,
  switches : Bytes,
  leds : Bytes,
) -> DeviceCapabilities {
  {
    event_types: decode_event_types(event_types),
    keys: decode_keys(keys),
    relative_axes: decode_relative_axes(relative_axes),
    absolute_axes: decode_absolute_axes(absolute_axes),
    switches: decode_switches(switches),
    leds: decode_leds(leds),
  }
}
