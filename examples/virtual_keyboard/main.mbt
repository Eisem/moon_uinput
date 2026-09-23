///|
fn main {
  try {
    let keyboard = @uinput.VirtualDeviceBuilder::new(
        name="MoonInput demo keyboard",
      )
      .key(A)
      .create()
    println("Created a virtual keyboard; sending an A key click.")
    keyboard.key_click(A)
    keyboard.close()
  } catch {
    error => println("Virtual keyboard unavailable: \{error.describe()}")
  } noraise {
    _ => ()
  }
}
