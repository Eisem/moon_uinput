///|
pub(all) struct OutputEvent {
  event_type : Int
  code : Int
  value : Int
} derive(Debug, Eq)

///|
pub extend OutputEvent with Debug::{to_repr}

///|
pub extend OutputEvent with Eq::{equal, not_equal}

///|
fn event_frame(event_type : Int, code : Int, value : Int) -> Array[OutputEvent] {
  [{ event_type, code, value, }, { event_type: 0, code: 0, value: 0, }]
}

///|
fn VirtualDevice::send_frame(
  self : VirtualDevice,
  events : Array[OutputEvent],
) -> Unit raise @errors.InputError {
  for event in events {
    check_errno(
      "write input event",
      self.native.emit(event.event_type, event.code, event.value),
    )
  }
}

///|
fn validate_output_event(
  event_type : Int,
  code : Int,
) -> Unit raise @errors.InputError {
  if event_type < 0 || event_type > 0x1f || code < 0 || code > 0xffff {
    raise InvalidOutputEvent(event_type~, code~)
  }
}

///|
/// Write one Linux input event without adding a frame boundary. Most callers
/// should use a helper that follows its data event with `sync()`.
pub fn VirtualDevice::emit(
  self : VirtualDevice,
  event_type : Int,
  code : Int,
  value : Int,
) -> Unit raise @errors.InputError {
  validate_output_event(event_type, code)
  check_errno("write input event", self.native.emit(event_type, code, value))
}

///|
/// End the current event frame with `EV_SYN/SYN_REPORT`.
pub fn VirtualDevice::sync(
  self : VirtualDevice,
) -> Unit raise @errors.InputError {
  self.emit(0, 0, 0)
}

///|
/// Press a configured key and end its frame.
pub fn VirtualDevice::key_down(
  self : VirtualDevice,
  key : @codes.KeyCode,
) -> Unit raise @errors.InputError {
  self.send_frame(event_frame(1, key.to_linux(), 1))
}

///|
/// Release a configured key and end its frame.
pub fn VirtualDevice::key_up(
  self : VirtualDevice,
  key : @codes.KeyCode,
) -> Unit raise @errors.InputError {
  self.send_frame(event_frame(1, key.to_linux(), 0))
}

///|
/// Press and release a key in two separately synchronized frames.
pub fn VirtualDevice::key_click(
  self : VirtualDevice,
  key : @codes.KeyCode,
) -> Unit raise @errors.InputError {
  self.key_down(key)
  self.key_up(key)
}
