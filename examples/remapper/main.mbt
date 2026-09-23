///|
fn main {
  let args = @env.args()
  if args.length() != 2 {
    println("Usage: moon run examples/remapper -- /dev/input/eventX")
    println(
      "CapsLock + H/J/K/L produces arrow keys. This grabs the chosen device.",
    )
    return
  }
  println("Starting remapper for \{args[1]}; press Ctrl+C to stop.")
  try @remap.run_keyboard_layer(args[1]) catch {
    error => println("MoonInput remapper error: \{error.describe()}")
  } noraise {
    _ => ()
  }
}
