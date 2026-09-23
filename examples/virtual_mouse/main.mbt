///|
fn main {
  try {
    let mouse = @uinput.VirtualDeviceBuilder::new(name="MoonInput demo mouse")
      .relative_axis(X)
      .relative_axis(Y)
      .key(ButtonLeft)
      .key(ButtonRight)
      .key(ButtonMiddle)
      .create()
    println("Created a virtual mouse; moving by 20, 10 and clicking left.")
    mouse.move_by(20, 10)
    mouse.button_click(Left)
    mouse.close()
  } catch {
    error => println("Virtual mouse unavailable: \{error.describe()}")
  } noraise {
    _ => ()
  }
}
