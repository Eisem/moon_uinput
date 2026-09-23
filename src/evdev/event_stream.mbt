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

///|
/// A blocking stream of complete evdev frames.
pub struct DevicePacketStream {
  device : Device
  packetizer : @event.Packetizer
}

///|
/// Read until the next non-empty `SYN_REPORT` frame is available.
///
/// Empty frames are skipped. Device I/O errors, including disconnection, are
/// propagated. A frame buffered when an error occurs is incomplete and is
/// not returned. If the caller retries after a transient error, the buffered
/// events remain pending until a later `SYN_REPORT` completes that frame.
pub fn DevicePacketStream::next(
  self : DevicePacketStream,
) -> @event.EventPacket raise @errors.InputError {
  for ;; {
    let event = self.device.read_event()
    match self.packetizer.push(event) {
      Some(packet) => break packet
      None => ()
    }
  }
}
