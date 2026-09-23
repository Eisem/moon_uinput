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

///|
/// A packet stream that replaces lost event frames with kernel state snapshots.
pub struct SyncedPacketStream {
  packets : DevicePacketStream
  device : Device
}

///|
/// Read the next complete event packet or state snapshot after `SYN_DROPPED`.
///
/// The packet containing `SYN_DROPPED` is discarded. Its frame ends at the
/// following `SYN_REPORT`; the current pressed keys and absolute-axis values
/// are queried at that point and returned as `Recovered`. Reading resumes at
/// the next frame. I/O and snapshot errors are propagated.
pub fn SyncedPacketStream::next(
  self : SyncedPacketStream,
) -> @event.SyncedPacket raise @errors.InputError {
  let packet = self.packets.next()
  @event.synchronize_packet(packet, () => self.device.state())
}
