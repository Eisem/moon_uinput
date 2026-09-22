///|
fn raw(event_type : Int, code : Int, value : Int) -> @event.RawEvent {
  { timestamp: { sec: 12L, usec: 34L, }, event_type, code, value, }
}

///|
test "decode key states" {
  debug_inspect(
    @event.decode(raw(1, 30, 1)),
    content=(
      #|Key({ timestamp: { sec: 12, usec: 34 }, code: A, state: Pressed })
    ),
  )
  debug_inspect(
    @event.decode(raw(1, 30, 0)),
    content=(
      #|Key({ timestamp: { sec: 12, usec: 34 }, code: A, state: Released })
    ),
  )
  debug_inspect(
    @event.decode(raw(1, 30, 2)),
    content=(
      #|Key({ timestamp: { sec: 12, usec: 34 }, code: A, state: Repeat })
    ),
  )
}

///|
test "decode relative absolute and sync events" {
  debug_inspect(
    @event.decode(raw(2, 0, 10)),
    content=(
      #|Relative({ timestamp: { sec: 12, usec: 34 }, axis: X, value: 10 })
    ),
  )
  debug_inspect(
    @event.decode(raw(2, 1, -5)),
    content=(
      #|Relative({ timestamp: { sec: 12, usec: 34 }, axis: Y, value: -5 })
    ),
  )
  debug_inspect(
    @event.decode(raw(3, 0, 512)),
    content=(
      #|Absolute({ timestamp: { sec: 12, usec: 34 }, axis: X, value: 512 })
    ),
  )
  debug_inspect(
    @event.decode(raw(0, 0, 0)),
    content=(
      #|Sync({ timestamp: { sec: 12, usec: 34 }, code: Report })
    ),
  )
}

///|
test "unknown codes and malformed key values are lossless" {
  debug_inspect(
    @event.decode(raw(1, 999, 1)),
    content=(
      #|Key(
      #|  {
      #|    timestamp: { sec: 12, usec: 34 },
      #|    code: Unknown(999),
      #|    state: Pressed,
      #|  },
      #|)
    ),
  )
  assert_true(@event.decode(raw(1, 30, 9)) == Unknown(raw(1, 30, 9)))
  assert_true(@event.decode(raw(99, 7, 8)) == Unknown(raw(99, 7, 8)))
}
