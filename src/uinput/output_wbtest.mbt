///|
test "key output frames end with SYN_REPORT" {
  let down = event_frame(1, 30, 1)
  assert_eq(down.length(), 2)
  assert_eq(down[0].event_type, 1)
  assert_eq(down[0].code, 30)
  assert_eq(down[0].value, 1)
  assert_eq(down[1].event_type, 0)
  assert_eq(down[1].code, 0)
  assert_eq(down[1].value, 0)
  let up = event_frame(1, 30, 0)
  assert_eq(up[0].value, 0)
  assert_eq(up[1].event_type, 0)
}

///|
test "raw output event validation prevents ABI truncation" {
  validate_output_event(0, 0)
  validate_output_event(0x1f, 0xffff)
  try validate_output_event(0x20, 0) catch {
    InvalidOutputEvent(..) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected invalid event type")
  }
  try validate_output_event(1, -1) catch {
    InvalidOutputEvent(..) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected invalid event code")
  }
}

///|
test "only advertised virtual capabilities can be emitted" {
  let keys = [30, 0x110]
  let relative_axes = [0, 1]
  let absolute_axes = [3]
  validate_configured_output(0, 0, keys, relative_axes, absolute_axes)
  validate_configured_output(1, 30, keys, relative_axes, absolute_axes)
  validate_configured_output(2, 1, keys, relative_axes, absolute_axes)
  validate_configured_output(3, 3, keys, relative_axes, absolute_axes)
  try
    validate_configured_output(1, 31, keys, relative_axes, absolute_axes)
  catch {
    UnsupportedOutputCapability(..) => ()
    _ => fail("unexpected capability error")
  } noraise {
    _ => fail("unadvertised key was accepted")
  }
  try
    validate_configured_output(2, 8, keys, relative_axes, absolute_axes)
  catch {
    UnsupportedOutputCapability(..) => ()
    _ => fail("unexpected capability error")
  } noraise {
    _ => fail("unadvertised relative axis was accepted")
  }
}

///|
test "unsupported sync codes and event families cannot slip through" {
  let keys = [30]
  let relative_axes : Array[Int] = []
  let absolute_axes : Array[Int] = []
  try
    validate_configured_output(0, 1, keys, relative_axes, absolute_axes)
  catch {
    UnsupportedOutputCapability(event_type~, code~) => {
      assert_eq(event_type, 0)
      assert_eq(code, 1)
    }
    _ => fail("expected unsupported sync code")
  } noraise {
    _ => fail("unsupported sync code was emitted")
  }
  try
    validate_configured_output(4, 0, keys, relative_axes, absolute_axes)
  catch {
    UnsupportedOutputCapability(event_type~, code~) => {
      assert_eq(event_type, 4)
      assert_eq(code, 0)
    }
    _ => fail("expected unsupported event family")
  } noraise {
    _ => fail("unsupported event family was emitted")
  }
}
