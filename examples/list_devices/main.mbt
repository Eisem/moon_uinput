///|
fn print_entry(entry : @evdev.DeviceDiscoveryEntry) -> Unit {
  match entry {
    Available(info) => {
      println("\{info.path}")
      println("  name: \{info.name}")
      println(
        "  id: bus=\{info.id.bus_type} vendor=\{info.id.vendor} product=\{info.id.product} version=\{info.id.version}",
      )
    }
    Unavailable(path~, error~) => {
      println("\{path}")
      println("  unavailable: \{error.describe()}")
    }
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() > 2 {
    println("Usage: moon run examples/list_devices [-- /dev/input]")
    return
  }
  let directory = if args.length() == 2 { args[1] } else { "/dev/input" }
  try @evdev.discover_devices(directory~) catch {
    error => println("MoonInput error: \{error.describe()}")
  } noraise {
    devices =>
      if devices.length() == 0 {
        println("No evdev devices found in \{directory}")
      } else {
        for device in devices {
          print_entry(device)
        }
      }
  }
}
