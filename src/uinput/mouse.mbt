///|
/// A supported standard mouse button.
pub(all) enum MouseButton {
  Left
  Right
  Middle
} derive(Debug, Eq)

///|
pub extend MouseButton with Debug::{to_repr}

///|
pub extend MouseButton with Eq::{equal, not_equal}

///|
fn button_code(button : MouseButton) -> Int {
  match button {
    Left => @codes.ButtonLeft.to_linux()
    Right => @codes.ButtonRight.to_linux()
    Middle => @codes.ButtonMiddle.to_linux()
  }
}

///|
fn movement_frame(dx : Int, dy : Int) -> Array[OutputEvent] {
  [
    { event_type: 2, code: 0, value: dx, },
    { event_type: 2, code: 1, value: dy, },
    { event_type: 0, code: 0, value: 0, },
  ]
}

///|
fn button_frame(button : MouseButton, pressed : Bool) -> Array[OutputEvent] {
  event_frame(1, button_code(button), if pressed { 1 } else { 0 })
}

///|
/// Move a configured relative mouse by `(dx, dy)` and end the frame.
pub fn VirtualDevice::move_by(
  self : VirtualDevice,
  dx : Int,
  dy : Int,
) -> Unit raise @errors.InputError {
  self.send_frame(movement_frame(dx, dy))
}

///|
/// Press a mouse button and end its frame.
pub fn VirtualDevice::button_down(
  self : VirtualDevice,
  button : MouseButton,
) -> Unit raise @errors.InputError {
  self.send_frame(button_frame(button, true))
}

///|
/// Release a mouse button and end its frame.
pub fn VirtualDevice::button_up(
  self : VirtualDevice,
  button : MouseButton,
) -> Unit raise @errors.InputError {
  self.send_frame(button_frame(button, false))
}

///|
/// Press and release a mouse button in two separately synchronized frames.
pub fn VirtualDevice::button_click(
  self : VirtualDevice,
  button : MouseButton,
) -> Unit raise @errors.InputError {
  self.button_down(button)
  self.button_up(button)
}
