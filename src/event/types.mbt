///|
/// Timestamp supplied by evdev for an input event.
pub(all) struct EventTimestamp {
  sec : Int64
  usec : Int64
} derive(Debug, Eq)

///|
pub extend EventTimestamp with Debug::{to_repr}

///|
pub extend EventTimestamp with Eq::{equal, not_equal}

///|
/// Stable MoonBit representation of the fields in Linux `struct input_event`.
pub(all) struct RawEvent {
  timestamp : EventTimestamp
  event_type : Int
  code : Int
  value : Int
} derive(Debug, Eq)

///|
pub extend RawEvent with Debug::{to_repr}

///|
pub extend RawEvent with Eq::{equal, not_equal}

///|
pub(all) enum KeyState {
  Released
  Pressed
  Repeat
} derive(Debug, Eq)

///|
pub extend KeyState with Debug::{to_repr}

///|
pub extend KeyState with Eq::{equal, not_equal}

///|
pub fn KeyState::from_linux(value : Int) -> KeyState? {
  match value {
    0 => Some(Released)
    1 => Some(Pressed)
    2 => Some(Repeat)
    _ => None
  }
}

///|
pub fn KeyState::to_linux(self : KeyState) -> Int {
  match self {
    Released => 0
    Pressed => 1
    Repeat => 2
  }
}

///|
pub(all) struct KeyEvent {
  timestamp : EventTimestamp
  code : @codes.KeyCode
  state : KeyState
} derive(Debug, Eq)

///|
pub extend KeyEvent with Debug::{to_repr}

///|
pub extend KeyEvent with Eq::{equal, not_equal}

///|
pub(all) struct RelativeEvent {
  timestamp : EventTimestamp
  axis : @codes.RelativeAxis
  value : Int
} derive(Debug, Eq)

///|
pub extend RelativeEvent with Debug::{to_repr}

///|
pub extend RelativeEvent with Eq::{equal, not_equal}

///|
pub(all) struct AbsoluteEvent {
  timestamp : EventTimestamp
  axis : @codes.AbsoluteAxis
  value : Int
} derive(Debug, Eq)

///|
pub extend AbsoluteEvent with Debug::{to_repr}

///|
pub extend AbsoluteEvent with Eq::{equal, not_equal}

///|
pub(all) struct SyncEvent {
  timestamp : EventTimestamp
  code : @codes.SyncCode
} derive(Debug, Eq)

///|
pub extend SyncEvent with Debug::{to_repr}

///|
pub extend SyncEvent with Eq::{equal, not_equal}

///|
pub(all) struct SwitchEvent {
  timestamp : EventTimestamp
  code : @codes.SwitchCode
  enabled : Bool
} derive(Debug, Eq)

///|
pub extend SwitchEvent with Debug::{to_repr}

///|
pub extend SwitchEvent with Eq::{equal, not_equal}

///|
pub(all) struct LedEvent {
  timestamp : EventTimestamp
  code : @codes.LedCode
  enabled : Bool
} derive(Debug, Eq)

///|
pub extend LedEvent with Debug::{to_repr}

///|
pub extend LedEvent with Eq::{equal, not_equal}

///|
/// Decoded input event. Unsupported types and malformed values retain their
/// original `RawEvent`, so decoding is forward compatible and lossless.
pub(all) enum InputEvent {
  Key(KeyEvent)
  Relative(RelativeEvent)
  Absolute(AbsoluteEvent)
  Sync(SyncEvent)
  Switch(SwitchEvent)
  Led(LedEvent)
  Misc(RawEvent)
  Unknown(RawEvent)
} derive(Debug, Eq)

///|
pub extend InputEvent with Debug::{to_repr}

///|
pub extend InputEvent with Eq::{equal, not_equal}
