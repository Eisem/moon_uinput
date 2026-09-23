///|
const RemapperName = "MoonInput remapper output"

///|
fn is_remapper_output(name : String, id : @evdev.DeviceId) -> Bool {
  name == RemapperName &&
  id.bus_type == 0x06 &&
  id.vendor == 0x1209 &&
  id.product == 0x0200
}

///|
fn require_keyboard(
  capabilities : @evdev.DeviceCapabilities,
) -> Unit raise @errors.InputError {
  let required : Array[@codes.KeyCode] = [CapsLock, H, J, K, L]
  for key in required {
    if !capabilities.supports_key(key) {
      raise InvalidRemapSource(
        reason="source must advertise CapsLock and H/J/K/L",
      )
    }
  }
}

///|
fn build_output(
  capabilities : @evdev.DeviceCapabilities,
) -> @uinput.VirtualDevice raise @errors.InputError {
  let builder = @uinput.VirtualDeviceBuilder::new(name=RemapperName)
    .identity(0x06, 0x1209, 0x0200, 1)
    .key(Left)
    .key(Down)
    .key(Up)
    .key(Right)
  for key in capabilities.keys {
    if key != CapsLock {
      ignore(builder.key(key))
    }
  }
  builder.create()
}

///|
fn write_outputs(
  device : @uinput.VirtualDevice,
  events : Array[@uinput.OutputEvent],
) -> Unit raise @errors.InputError {
  for event in events {
    device.emit(event.event_type, event.code, event.value)
  }
}

///|
fn release_quietly(
  mapper : LayerRemapper,
  device : @uinput.VirtualDevice,
) -> Unit {
  for event in mapper.release_all() {
    device.emit(event.event_type, event.code, event.value) catch {
      _ => ()
    }
  }
}

///|
/// Remap one explicitly selected physical keyboard until it disconnects or
/// reading fails. The virtual keyboard is created before grabbing the source;
/// errors release held output keys, ungrab, and close both devices.
pub fn run_keyboard_layer(path : String) -> Unit raise @errors.InputError {
  let source = @evdev.Device::open(path)
  errdefer (source.close() catch { _ => () })
  if is_remapper_output(source.name(), source.id()) {
    raise InvalidRemapSource(
      reason="selected device is a MoonInput remapper output",
    )
  }
  let capabilities = source.capabilities()
  require_keyboard(capabilities)
  let output = build_output(capabilities)
  errdefer (output.close() catch { _ => () })
  let mapper = LayerRemapper::new()
  errdefer {
    release_quietly(mapper, output)
    source.ungrab() catch {
      _ => ()
    }
  }
  source.grab()
  let stream = source.synced_packets()
  for ;; {
    write_outputs(output, mapper.process(stream.next()))
  }
}
