///|
extern "C" fn wait_for_device_node() -> Unit = "mooninput_roundtrip_wait"

///|
fn event_node(sysname : String) -> String raise @errors.InputError {
  let directory = "/sys/devices/virtual/input/\{sysname}"
  // uinput device-node registration is asynchronous after UI_DEV_CREATE.
  for _ in 0..<100 {
    let entries = @fs.read_dir(directory) catch { _ => [] }
    for name in entries {
      if name.has_prefix("event") {
        return "/dev/input/\{name}"
      }
    }
    wait_for_device_node()
  }
  raise RoundTripFailed(
    reason="the created device has no event node after 1 second",
  )
}

///|
fn contains_key(
  packet : @event.EventPacket,
  code : @codes.KeyCode,
  state : @event.KeyState,
) -> Bool {
  packet.events.any(input => {
    match input {
      Key(key) => key.code == code && key.state == state
      _ => false
    }
  })
}

///|
async fn roundtrip() -> Unit {
  let output = @uinput.VirtualDeviceBuilder::new(
      name="MoonInput roundtrip test",
    )
    .key(A)
    .create()
  errdefer (output.close() catch { _ => () })
  let path = event_node(output.sysname())
  let input = @evdev.Device::open(path)
  errdefer (input.close() catch { _ => () })
  let packets = input.packets()
  output.key_down(A)
  output.key_up(A)
  let down = packets.next()
  let up = packets.next()
  if !contains_key(down, A, Pressed) || !contains_key(up, A, Released) {
    raise @errors.InputError::RoundTripFailed(
      reason="A press/release was not read back from evdev",
    )
  }
  input.close()
  let async_input = @evdev.Device::open(path)
  errdefer (async_input.close() catch { _ => () })
  let async_packets = async_input.async_events().packets()
  defer async_packets.close()
  output.key_down(A)
  output.key_up(A)
  @async.with_timeout(2000, () => {
    let async_down = async_packets.next()
    let async_up = async_packets.next()
    if !contains_key(async_down, A, Pressed) ||
      !contains_key(async_up, A, Released) {
      raise @errors.InputError::RoundTripFailed(
        reason="asynchronous A press/release was not read back",
      )
    }
  })
  async_input.close()
  output.close()
  println("UINPUT_ROUNDTRIP_OK")
}

///|
async fn main {
  try roundtrip() catch {
    error => println("MoonInput error: \{error}")
  } noraise {
    _ => ()
  }
}
