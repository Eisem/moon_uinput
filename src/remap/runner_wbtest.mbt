///|
test "remapper rejects its own virtual identity" {
  let identity : @evdev.DeviceId = {
    bus_type: 0x06,
    vendor: 0x1209,
    product: 0x0200,
    version: 1,
  }
  assert_true(is_remapper_output(RemapperName, identity))
  assert_false(is_remapper_output("Another keyboard", identity))
  assert_false(
    is_remapper_output("MoonInput remapper output", {
      bus_type: 0x03,
      vendor: 0x1209,
      product: 0x0200,
      version: 1,
    }),
  )
  assert_false(
    is_remapper_output("MoonInput remapper output", {
      bus_type: 0x06,
      vendor: 0x1209,
      product: 0x0201,
      version: 1,
    }),
  )
}

///|
test "remapper rejects input without required keyboard capabilities" {
  let capabilities = @evdev.DeviceCapabilities::empty()
  try require_keyboard(capabilities) catch {
    InvalidRemapSource(reason~) =>
      assert_eq(reason, "source must advertise CapsLock and H/J/K/L")
    _ => fail("expected InvalidRemapSource")
  } noraise {
    _ => fail("empty capabilities were accepted")
  }
}
