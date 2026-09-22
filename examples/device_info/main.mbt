///|
fn print_device(path : String) -> Unit raise @errors.InputError {
  let device = @evdev.Device::open(path)
  let id = device.id()
  let capabilities = device.capabilities()
  println("Name: \{device.name()}")
  println("Path: \{device.path()}")
  println(
    "ID: bus=\{id.bus_type} vendor=\{id.vendor} product=\{id.product} version=\{id.version}",
  )
  println("Event types: \{Repr(capabilities.event_types)}")
  println("Keys/buttons: \{Repr(capabilities.keys)}")
  println("Relative axes: \{Repr(capabilities.relative_axes)}")
  println("Absolute axes: \{Repr(capabilities.absolute_axes)}")
  println("Switches: \{Repr(capabilities.switches)}")
  println("LEDs: \{Repr(capabilities.leds)}")
  device.close()
}

///|
fn main {
  let args = @env.args()
  if args.length() != 2 {
    println("Usage: moon run examples/device_info -- /dev/input/eventX")
    return
  }
  try print_device(args[1]) catch {
    error => println("MoonInput error: \{error.describe()}")
  } noraise {
    _ => ()
  }
}
