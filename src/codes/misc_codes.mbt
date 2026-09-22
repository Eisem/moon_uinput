///|
pub(all) enum SyncCode {
  Report
  Config
  MultiTouchReport
  Dropped
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend SyncCode with Debug::{to_repr}

///|
pub extend SyncCode with Eq::{equal, not_equal}

///|
pub fn SyncCode::from_linux(value : Int) -> SyncCode {
  match value {
    0 => Report
    1 => Config
    2 => MultiTouchReport
    3 => Dropped
    value => Unknown(value)
  }
}

///|
pub fn SyncCode::to_linux(self : SyncCode) -> Int {
  match self {
    Report => 0
    Config => 1
    MultiTouchReport => 2
    Dropped => 3
    Unknown(value) => value
  }
}

///|
pub(all) enum SwitchCode {
  Lid
  TabletMode
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend SwitchCode with Debug::{to_repr}

///|
pub extend SwitchCode with Eq::{equal, not_equal}

///|
pub fn SwitchCode::from_linux(value : Int) -> SwitchCode {
  match value {
    0 => Lid
    1 => TabletMode
    value => Unknown(value)
  }
}

///|
pub fn SwitchCode::to_linux(self : SwitchCode) -> Int {
  match self {
    Lid => 0
    TabletMode => 1
    Unknown(value) => value
  }
}

///|
pub(all) enum LedCode {
  NumLock
  CapsLock
  ScrollLock
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend LedCode with Debug::{to_repr}

///|
pub extend LedCode with Eq::{equal, not_equal}

///|
pub fn LedCode::from_linux(value : Int) -> LedCode {
  match value {
    0 => NumLock
    1 => CapsLock
    2 => ScrollLock
    value => Unknown(value)
  }
}

///|
pub fn LedCode::to_linux(self : LedCode) -> Int {
  match self {
    NumLock => 0
    CapsLock => 1
    ScrollLock => 2
    Unknown(value) => value
  }
}
