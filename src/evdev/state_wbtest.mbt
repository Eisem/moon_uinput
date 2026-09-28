///|
test "state snapshot performs only required live queries" {
  let mut key_queries = 0
  let mut axis_bitmap_queries = 0
  let mut axis_value_queries = 0
  let state = snapshot_device_state(
    () => {
      key_queries += 1
      [0x00, 0x00, 0x00, 0x40]
    },
    () => {
      axis_bitmap_queries += 1
      [0x03]
    },
    axis => {
      axis_value_queries += 1
      {
        value: axis.to_linux() + 100,
        minimum: 0,
        maximum: 1000,
        fuzz: 0,
        flat: 0,
        resolution: 1,
      }
    },
  )
  assert_eq(key_queries, 1)
  assert_eq(axis_bitmap_queries, 1)
  assert_eq(axis_value_queries, 2)
  debug_inspect(
    state,
    content=(
      #|{
      #|  pressed_keys: [A],
      #|  absolute_axes: [{ axis: X, value: 100 }, { axis: Y, value: 101 }],
      #|}
    ),
  )
}

///|
test "state snapshot with no absolute axes issues no value queries" {
  let mut key_queries = 0
  let mut axis_bitmap_queries = 0
  let mut axis_value_queries = 0
  let state = snapshot_device_state(
    () => {
      key_queries += 1
      b""
    },
    () => {
      axis_bitmap_queries += 1
      b""
    },
    _axis => {
      axis_value_queries += 1
      { value: 0, minimum: 0, maximum: 0, fuzz: 0, flat: 0, resolution: 0, }
    },
  )
  assert_eq(key_queries, 1)
  assert_eq(axis_bitmap_queries, 1)
  assert_eq(axis_value_queries, 0)
  debug_inspect(state, content="{ pressed_keys: [], absolute_axes: [] }")
}

///|
test "state snapshot propagates an intermediate absolute axis query error" {
  let mut axis_value_queries = 0
  try
    snapshot_device_state(() => b"", () => [0x03], _axis => {
      axis_value_queries += 1
      if axis_value_queries == 2 {
        raise DeviceDisconnected
      }
      { value: 55, minimum: 0, maximum: 100, fuzz: 0, flat: 0, resolution: 1, }
    })
  catch {
    DeviceDisconnected => assert_eq(axis_value_queries, 2)
    _ => fail("unexpected state snapshot error")
  } noraise {
    _ => fail("expected an axis query error")
  }
}
