///|
/// Linux input event families.
pub(all) enum EventType {
  Sync
  Key
  Relative
  Absolute
  Misc
  Switch
  Led
  Repeat
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend EventType with Debug::{to_repr}

///|
pub extend EventType with Eq::{equal, not_equal}

///|
/// Decode a Linux `EV_*` value without rejecting future kernel additions.
pub fn EventType::from_linux(value : Int) -> EventType {
  match value {
    0 => Sync
    1 => Key
    2 => Relative
    3 => Absolute
    4 => Misc
    5 => Switch
    17 => Led
    20 => Repeat
    value => Unknown(value)
  }
}

///|
/// Return the Linux ABI value for this event family.
pub fn EventType::to_linux(self : EventType) -> Int {
  match self {
    Sync => 0
    Key => 1
    Relative => 2
    Absolute => 3
    Misc => 4
    Switch => 5
    Led => 17
    Repeat => 20
    Unknown(value) => value
  }
}
