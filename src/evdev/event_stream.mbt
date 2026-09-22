///|
/// A blocking event stream. `next` either returns one event or raises a
/// structured I/O/disconnection error; it never spins on EOF.
pub struct EventStream {
  device : Device
}

///|
pub fn EventStream::next(
  self : EventStream,
) -> @event.InputEvent raise @errors.InputError {
  self.device.read_event()
}
