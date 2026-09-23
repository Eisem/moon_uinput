///|
/// Current absolute-axis value reported while recovering from event loss.
pub(all) struct AbsoluteAxisState {
  axis : @codes.AbsoluteAxis
  value : Int
} derive(Debug, Eq)

///|
pub extend AbsoluteAxisState with Debug::{to_repr}

///|
pub extend AbsoluteAxisState with Eq::{equal, not_equal}

///|
/// A device state snapshot suitable for rebuilding application state after
/// evdev reports `SYN_DROPPED`.
pub(all) struct DeviceState {
  pressed_keys : Array[@codes.KeyCode]
  absolute_axes : Array[AbsoluteAxisState]
} derive(Debug, Eq)

///|
pub extend DeviceState with Debug::{to_repr}

///|
pub extend DeviceState with Eq::{equal, not_equal}

///|
/// A normal complete event packet or a state snapshot emitted after loss.
pub(all) enum SyncedPacket {
  Events(EventPacket)
  Recovered(DeviceState)
} derive(Debug, Eq)

///|
pub extend SyncedPacket with Debug::{to_repr}

///|
pub extend SyncedPacket with Eq::{equal, not_equal}

///|
fn EventPacket::contains_syn_dropped(self : EventPacket) -> Bool {
  self.events.any(event => {
    match event {
      Sync(sync) => sync.code == Dropped
      _ => false
    }
  })
}

///|
pub fn synchronize_packet(
  packet : EventPacket,
  state_source : () -> DeviceState raise @errors.InputError,
) -> SyncedPacket raise @errors.InputError {
  if packet.contains_syn_dropped() {
    Recovered(state_source())
  } else {
    Events(packet)
  }
}
