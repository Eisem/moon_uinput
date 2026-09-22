///|
pub(all) enum RelativeAxis {
  X
  Y
  HorizontalWheel
  Wheel
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend RelativeAxis with Debug::{to_repr}

///|
pub extend RelativeAxis with Eq::{equal, not_equal}

///|
pub fn RelativeAxis::from_linux(value : Int) -> RelativeAxis {
  match value {
    0 => X
    1 => Y
    6 => HorizontalWheel
    8 => Wheel
    value => Unknown(value)
  }
}

///|
pub fn RelativeAxis::to_linux(self : RelativeAxis) -> Int {
  match self {
    X => 0
    Y => 1
    HorizontalWheel => 6
    Wheel => 8
    Unknown(value) => value
  }
}

///|
pub(all) enum AbsoluteAxis {
  X
  Y
  Z
  Rx
  Ry
  Rz
  Throttle
  Rudder
  Wheel
  Gas
  Brake
  Hat0X
  Hat0Y
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend AbsoluteAxis with Debug::{to_repr}

///|
pub extend AbsoluteAxis with Eq::{equal, not_equal}

///|
pub fn AbsoluteAxis::from_linux(value : Int) -> AbsoluteAxis {
  match value {
    0 => X
    1 => Y
    2 => Z
    3 => Rx
    4 => Ry
    5 => Rz
    6 => Throttle
    7 => Rudder
    8 => Wheel
    9 => Gas
    10 => Brake
    16 => Hat0X
    17 => Hat0Y
    value => Unknown(value)
  }
}

///|
pub fn AbsoluteAxis::to_linux(self : AbsoluteAxis) -> Int {
  match self {
    X => 0
    Y => 1
    Z => 2
    Rx => 3
    Ry => 4
    Rz => 5
    Throttle => 6
    Rudder => 7
    Wheel => 8
    Gas => 9
    Brake => 10
    Hat0X => 16
    Hat0Y => 17
    Unknown(value) => value
  }
}
