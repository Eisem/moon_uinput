///|
struct ActiveKey {
  source : @codes.KeyCode
  output : @codes.KeyCode
}

///|
/// Stateful CapsLock plus H/J/K/L direction-key mapper. CapsLock is consumed
/// as a layer key. Output events are grouped into one SYN_REPORT frame per
/// nonempty source packet; recovery snapshots reconcile held output keys.
pub struct LayerRemapper {
  mut caps_down : Bool
  mut active : Array[ActiveKey]
}

///|
pub fn LayerRemapper::new() -> LayerRemapper {
  { caps_down: false, active: [], }
}

///|
fn LayerRemapper::mapped_key(
  self : LayerRemapper,
  key : @codes.KeyCode,
) -> @codes.KeyCode {
  if self.caps_down {
    match key {
      H => Left
      J => Down
      K => Up
      L => Right
      _ => key
    }
  } else {
    key
  }
}

///|
fn LayerRemapper::find_active(
  self : LayerRemapper,
  source : @codes.KeyCode,
) -> @codes.KeyCode? {
  for entry in self.active {
    if entry.source == source {
      return Some(entry.output)
    }
  }
  None
}

///|
fn LayerRemapper::output_is_held(
  self : LayerRemapper,
  output : @codes.KeyCode,
) -> Bool {
  self.active.any(entry => entry.output == output)
}

///|
fn output_keys(active : Array[ActiveKey]) -> Array[@codes.KeyCode] {
  let result : Array[@codes.KeyCode] = []
  for entry in active {
    if !result.contains(entry.output) {
      result.push(entry.output)
    }
  }
  result
}

///|
fn push_key(
  events : Array[@uinput.OutputEvent],
  key : @codes.KeyCode,
  value : Int,
) -> Unit {
  events.push({ event_type: 1, code: key.to_linux(), value, })
}

///|
fn finish_frame(
  events : Array[@uinput.OutputEvent],
) -> Array[@uinput.OutputEvent] {
  if !events.is_empty() {
    events.push({ event_type: 0, code: 0, value: 0, })
  }
  events
}

///|
fn LayerRemapper::press(
  self : LayerRemapper,
  source : @codes.KeyCode,
  events : Array[@uinput.OutputEvent],
) -> Unit {
  if source == CapsLock {
    self.caps_down = true
    return
  }
  if self.find_active(source) is Some(_) {
    return
  }
  let output = self.mapped_key(source)
  let already_held = self.output_is_held(output)
  self.active.push({ source, output, })
  if !already_held {
    push_key(events, output, 1)
  }
}

///|
fn LayerRemapper::release(
  self : LayerRemapper,
  source : @codes.KeyCode,
  events : Array[@uinput.OutputEvent],
) -> Unit {
  if source == CapsLock {
    self.caps_down = false
    return
  }
  let output = self.find_active(source)
  let kept : Array[ActiveKey] = []
  for entry in self.active {
    if entry.source != source {
      kept.push(entry)
    }
  }
  self.active = kept
  match output {
    Some(key) if !self.output_is_held(key) => push_key(events, key, 0)
    _ => ()
  }
}

///|
fn LayerRemapper::repeat(
  self : LayerRemapper,
  source : @codes.KeyCode,
  events : Array[@uinput.OutputEvent],
) -> Unit {
  match self.find_active(source) {
    Some(key) => push_key(events, key, 2)
    None => ()
  }
}

///|
fn LayerRemapper::recover(
  self : LayerRemapper,
  state : @event.DeviceState,
) -> Array[@uinput.OutputEvent] {
  let old_outputs = output_keys(self.active)
  let next : Array[ActiveKey] = []
  self.caps_down = state.pressed_keys.contains(CapsLock)
  for entry in self.active {
    if state.pressed_keys.contains(entry.source) {
      next.push(entry)
    }
  }
  for source in state.pressed_keys {
    if source != CapsLock && !next.any(entry => entry.source == source) {
      next.push({ source, output: self.mapped_key(source), })
    }
  }
  let new_outputs = output_keys(next)
  let events : Array[@uinput.OutputEvent] = []
  for key in old_outputs {
    if !new_outputs.contains(key) {
      push_key(events, key, 0)
    }
  }
  for key in new_outputs {
    if !old_outputs.contains(key) {
      push_key(events, key, 1)
    }
  }
  self.active = next
  finish_frame(events)
}

///|
/// Transform one complete input packet or recovered device snapshot into
/// zero or more output events. A nonempty result always ends in SYN_REPORT.
pub fn LayerRemapper::process(
  self : LayerRemapper,
  packet : @event.SyncedPacket,
) -> Array[@uinput.OutputEvent] {
  match packet {
    Recovered(state) => self.recover(state)
    Events(frame) => {
      let events : Array[@uinput.OutputEvent] = []
      for input in frame.events {
        match input {
          Key(key) =>
            match key.state {
              Pressed => self.press(key.code, events)
              Released => self.release(key.code, events)
              Repeat => self.repeat(key.code, events)
            }
          _ => ()
        }
      }
      finish_frame(events)
    }
  }
}

///|
/// Release every output key still held by this mapper before shutdown.
pub fn LayerRemapper::release_all(
  self : LayerRemapper,
) -> Array[@uinput.OutputEvent] {
  let events : Array[@uinput.OutputEvent] = []
  for key in output_keys(self.active) {
    push_key(events, key, 0)
  }
  self.active = []
  self.caps_down = false
  finish_frame(events)
}
