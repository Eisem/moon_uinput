///|
test "capability bitmap handles boundaries and invalid codes" {
  let bitmap : Bytes = [0x81, 0x01]
  assert_true(bitmap_contains(bitmap, 0))
  assert_true(bitmap_contains(bitmap, 7))
  assert_true(bitmap_contains(bitmap, 8))
  assert_false(bitmap_contains(bitmap, 1))
  assert_false(bitmap_contains(bitmap, -1))
  assert_false(bitmap_contains(bitmap, 16))
}

///|
test "capability bitmaps decode into typed values without losing unknowns" {
  let key_bits = Bytes::makei(35, index => {
    match index {
      3 => 0x40 // KEY_A = 30
      31 => 0x80 // unknown key code 255
      34 => 0x01 // BTN_LEFT = 272
      _ => 0x00
    }
  })
  let capabilities = decode_capability_bitmaps(
    [0x8F, 0x00, 0x02], // SYN, KEY, REL, ABS, unknown 7, LED
    key_bits,
    [0x01, 0x01], // REL_X and REL_WHEEL
    [0x01, 0x00, 0x02], // ABS_X and ABS_HAT0Y
    [0x01], // SW_LID
    [0x02], // LED_CAPSL
  )
  assert_true(capabilities.supports_event(Key))
  assert_true(capabilities.supports_event(Unknown(7)))
  assert_true(capabilities.supports_key(A))
  assert_true(capabilities.supports_key(ButtonLeft))
  assert_true(capabilities.supports_key(Unknown(255)))
  assert_true(capabilities.supports_relative_axis(Wheel))
  assert_true(capabilities.supports_absolute_axis(Hat0Y))
  assert_true(capabilities.supports_switch(Lid))
  assert_true(capabilities.supports_led(CapsLock))
  assert_false(capabilities.supports_key(B))
  guard capabilities.absolute_axis(X) is Some(entry) else {
    fail("expected ABS_X capability")
  }
  inspect(entry.info is None, content="true")
}
