///|
/// Print complete evdev frames using the async runtime's raw descriptor API.
/// The original handle is closed only after its independently owned async
/// stream, so no read can race its close in this example.
async fn monitor_async(path : String) -> Unit {
  let device = @evdev.Device::open(path)
  defer (device.close() catch { _ => () })
  println("Device: \{device.name()}")
  println("Path: \{device.path()}")
  let packets = device.async_synced_packets()
  defer packets.close()
  println("Async monitoring; press Ctrl+C to stop.")
  for ;; {
    match packets.next() {
      Events(packet) => {
        println("Frame at \{packet.timestamp.sec}.\{packet.timestamp.usec}")
        for event in packet.events {
          println("  \{event.to_repr()}")
        }
      }
      Recovered(state) =>
        println("Recovered after SYN_DROPPED: \{state.to_repr()}")
    }
    @async.pause()
  }
}

///|
async fn main {
  let args = @env.args()
  if args.length() != 2 {
    println("Usage: moon run examples/async_monitor -- /dev/input/eventX")
    return
  }
  monitor_async(args[1])
}
