///|
fn key_state_name(state : @event.KeyState) -> String {
  match state {
    Released => "RELEASED"
    Pressed => "PRESSED"
    Repeat => "REPEAT"
  }
}

///|
fn print_event(input : @event.InputEvent) -> Unit {
  match input {
    Key(key) =>
      println("KEY \{key.code.to_repr()} \{key_state_name(key.state)}")
    Relative(relative) =>
      println("REL \{relative.axis.to_repr()} \{relative.value}")
    Absolute(absolute) =>
      println("ABS \{absolute.axis.to_repr()} \{absolute.value}")
    Sync(sync) => println("SYN \{sync.code.to_repr()}")
    Switch(switch) => println("SW \{switch.code.to_repr()} \{switch.enabled}")
    Led(led) => println("LED \{led.code.to_repr()} \{led.enabled}")
    Misc(raw) => println("MSC code=\{raw.code} value=\{raw.value}")
    Unknown(raw) =>
      println(
        "UNKNOWN type=\{raw.event_type} code=\{raw.code} value=\{raw.value}",
      )
  }
}

///|
fn monitor(path : String) -> Unit raise @errors.InputError {
  let device = @evdev.Device::open(path)
  println("Device: \{device.name()}")
  println("Path: \{device.path()}")
  println("Monitoring input; press Ctrl+C to stop.")
  let events = device.events()
  for ;; {
    print_event(events.next())
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() != 2 {
    println("Usage: moon run examples/monitor -- /dev/input/eventX")
    return
  }
  try monitor(args[1]) catch {
    error => println("MoonInput error: \{error.describe()}")
  } noraise {
    _ => ()
  }
}
