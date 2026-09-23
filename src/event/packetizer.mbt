///|
/// A complete group of events terminated by one `SYN_REPORT`. The report
/// marker is represented by `timestamp` and is not repeated in `events`.
pub(all) struct EventPacket {
  timestamp : EventTimestamp
  events : Array[InputEvent]
} derive(Debug, Eq)

///|
pub extend EventPacket with Debug::{to_repr}

///|
pub extend EventPacket with Eq::{equal, not_equal}

///|
/// Incrementally groups decoded events into evdev frames.
///
/// A `SYN_REPORT` emits a non-empty packet. Empty reports are ignored.
/// Other sync events, including `SYN_DROPPED` and unknown sync codes, remain
/// in the packet so higher layers can interpret them without data loss.
pub struct Packetizer {
  mut pending : Array[InputEvent]
}

///|
/// Create an empty event packetizer.
pub fn Packetizer::new() -> Packetizer {
  { pending: [], }
}

///|
/// Add one event and return a packet when it ends a non-empty frame.
///
/// The `SYN_REPORT` event itself is omitted from packet events and its
/// timestamp is attached to the resulting packet. Events buffered before a
/// stream error are incomplete and should be discarded by the caller.
pub fn Packetizer::push(self : Packetizer, event : InputEvent) -> EventPacket? {
  match event {
    Sync(sync) if sync.code == Report =>
      if self.pending.length() == 0 {
        None
      } else {
        let packet = Some({ timestamp: sync.timestamp, events: self.pending, })
        self.pending = []
        packet
      }
    event => {
      self.pending.push(event)
      None
    }
  }
}
