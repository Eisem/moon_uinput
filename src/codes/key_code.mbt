///|
/// Keyboard keys and mouse buttons supported by MoonInput v0.1.
/// Unknown codes are retained so newer kernels remain readable.
pub(all) enum KeyCode {
  Escape
  Digit1
  Digit2
  Digit3
  Digit4
  Digit5
  Digit6
  Digit7
  Digit8
  Digit9
  Digit0
  Backspace
  Tab
  Q
  W
  E
  R
  T
  Y
  U
  I
  O
  P
  Enter
  LeftCtrl
  A
  S
  D
  F
  G
  H
  J
  K
  L
  LeftShift
  Z
  X
  C
  V
  B
  N
  M
  RightShift
  LeftAlt
  Space
  CapsLock
  F1
  F2
  F3
  F4
  F5
  F6
  F7
  F8
  F9
  F10
  F11
  F12
  RightCtrl
  RightAlt
  Up
  Left
  Right
  Down
  ButtonLeft
  ButtonRight
  ButtonMiddle
  Unknown(Int)
} derive(Debug, Eq)

///|
pub extend KeyCode with Debug::{to_repr}

///|
pub extend KeyCode with Eq::{equal, not_equal}

///|
pub fn KeyCode::from_linux(value : Int) -> KeyCode {
  match value {
    1 => Escape
    2 => Digit1
    3 => Digit2
    4 => Digit3
    5 => Digit4
    6 => Digit5
    7 => Digit6
    8 => Digit7
    9 => Digit8
    10 => Digit9
    11 => Digit0
    14 => Backspace
    15 => Tab
    16 => Q
    17 => W
    18 => E
    19 => R
    20 => T
    21 => Y
    22 => U
    23 => I
    24 => O
    25 => P
    28 => Enter
    29 => LeftCtrl
    30 => A
    31 => S
    32 => D
    33 => F
    34 => G
    35 => H
    36 => J
    37 => K
    38 => L
    42 => LeftShift
    44 => Z
    45 => X
    46 => C
    47 => V
    48 => B
    49 => N
    50 => M
    54 => RightShift
    56 => LeftAlt
    57 => Space
    58 => CapsLock
    59 => F1
    60 => F2
    61 => F3
    62 => F4
    63 => F5
    64 => F6
    65 => F7
    66 => F8
    67 => F9
    68 => F10
    87 => F11
    88 => F12
    97 => RightCtrl
    100 => RightAlt
    103 => Up
    105 => Left
    106 => Right
    108 => Down
    0x110 => ButtonLeft
    0x111 => ButtonRight
    0x112 => ButtonMiddle
    value => Unknown(value)
  }
}

///|
pub fn KeyCode::to_linux(self : KeyCode) -> Int {
  match self {
    Escape => 1
    Digit1 => 2
    Digit2 => 3
    Digit3 => 4
    Digit4 => 5
    Digit5 => 6
    Digit6 => 7
    Digit7 => 8
    Digit8 => 9
    Digit9 => 10
    Digit0 => 11
    Backspace => 14
    Tab => 15
    Q => 16
    W => 17
    E => 18
    R => 19
    T => 20
    Y => 21
    U => 22
    I => 23
    O => 24
    P => 25
    Enter => 28
    LeftCtrl => 29
    A => 30
    S => 31
    D => 32
    F => 33
    G => 34
    H => 35
    J => 36
    K => 37
    L => 38
    LeftShift => 42
    Z => 44
    X => 45
    C => 46
    V => 47
    B => 48
    N => 49
    M => 50
    RightShift => 54
    LeftAlt => 56
    Space => 57
    CapsLock => 58
    F1 => 59
    F2 => 60
    F3 => 61
    F4 => 62
    F5 => 63
    F6 => 64
    F7 => 65
    F8 => 66
    F9 => 67
    F10 => 68
    F11 => 87
    F12 => 88
    RightCtrl => 97
    RightAlt => 100
    Up => 103
    Left => 105
    Right => 106
    Down => 108
    ButtonLeft => 0x110
    ButtonRight => 0x111
    ButtonMiddle => 0x112
    Unknown(value) => value
  }
}
