///|
test "virtual device builder deduplicates capabilities" {
  let builder = @uinput.VirtualDeviceBuilder::new()
    .key(A)
    .key(A)
    .relative_axis(X)
  assert_eq(builder.keys.length(), 1)
  assert_eq(builder.relative_axes.length(), 1)
}

///|
test "virtual device builder rejects missing capabilities" {
  try {
    @uinput.VirtualDeviceBuilder::new().validate()
    fail("expected validation error")
  } catch {
    @errors.InvalidVirtualDeviceConfig(_) => ()
    _ => fail("unexpected error")
  }
}

///|
test "virtual device builder rejects invalid identity and axis ranges" {
  try {
    @uinput.VirtualDeviceBuilder::new().identity(0, -1, 1, 1).key(A).validate()
    fail("expected identity error")
  } catch {
    @errors.InvalidVirtualDeviceConfig(_) => ()
    _ => fail("unexpected error")
  }
  try {
    @uinput.VirtualDeviceBuilder::new()
    .absolute_axis({
      axis: X,
      minimum: 5,
      maximum: 5,
      fuzz: 0,
      flat: 0,
      resolution: 0,
    })
    .validate()
    fail("expected axis error")
  } catch {
    @errors.InvalidVirtualDeviceConfig(_) => ()
    _ => fail("unexpected error")
  }
}
