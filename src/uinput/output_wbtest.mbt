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
