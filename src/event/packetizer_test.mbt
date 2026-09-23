///|
fn packet_test_time(sec : Int64, usec : Int64) -> @event.EventTimestamp {
  { sec, usec, }
}

///|
fn packet_test_key(code : @codes.KeyCode, value : Int) -> @event.InputEvent {
  let state = @event.KeyState::from_linux(value).unwrap()
  Key({ timestamp: packet_test_time(10L, value.to_int64()), code, state, })
}

///|
fn packet_test_sync(code : @codes.SyncCode, sec : Int64) -> @event.InputEvent {
  Sync({ timestamp: packet_test_time(sec, 999L), code, })
}

///|
test "packetizer groups relative and key events at SYN_REPORT" {
  let packetizer = @event.Packetizer::new()
  assert_true(
    packetizer.push(
      Relative({ timestamp: packet_test_time(10L, 1L), axis: X, value: 4, }),
    )
    is None,
  )
  assert_true(packetizer.push(packet_test_key(A, 1)) is None)
  let packet = packetizer.push(packet_test_sync(Report, 11L))
  debug_inspect(
    packet,
    content=(
      #|Some(
      #|  {
      #|    timestamp: { sec: 11, usec: 999 },
      #|    events: [
      #|      Relative({ timestamp: { sec: 10, usec: 1 }, axis: X, value: 4 }),
      #|      Key({ timestamp: { sec: 10, usec: 1 }, code: A, state: Pressed }),
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "packetizer ignores empty frames and separates consecutive packets" {
  let packetizer = @event.Packetizer::new()
  assert_true(packetizer.push(packet_test_sync(Report, 1L)) is None)
  assert_true(packetizer.push(packet_test_key(A, 1)) is None)
  let first = packetizer.push(packet_test_sync(Report, 2L))
  assert_true(first is Some(_))
  assert_true(packetizer.push(packet_test_key(B, 0)) is None)
  let second = packetizer.push(packet_test_sync(Report, 3L))
  debug_inspect(
    second,
    content=(
      #|Some(
      #|  {
      #|    timestamp: { sec: 3, usec: 999 },
      #|    events: [Key({ timestamp: { sec: 10, usec: 0 }, code: B, state: Released })],
      #|  },
      #|)
    ),
  )
  assert_true(packetizer.push(packet_test_sync(Report, 4L)) is None)
}

///|
test "packetizer retains non-report and unknown sync events" {
  let packetizer = @event.Packetizer::new()
  assert_true(packetizer.push(packet_test_key(A, 1)) is None)
  assert_true(packetizer.push(packet_test_sync(Dropped, 1L)) is None)
  assert_true(packetizer.push(packet_test_sync(Unknown(42), 1L)) is None)
  debug_inspect(
    packetizer.push(packet_test_sync(Report, 2L)),
    content=(
      #|Some(
      #|  {
      #|    timestamp: { sec: 2, usec: 999 },
      #|    events: [
      #|      Key({ timestamp: { sec: 10, usec: 1 }, code: A, state: Pressed }),
      #|      Sync({ timestamp: { sec: 1, usec: 999 }, code: Dropped }),
      #|      Sync({ timestamp: { sec: 1, usec: 999 }, code: Unknown(42) }),
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "packetizer keeps incomplete frames buffered until a report arrives" {
  let packetizer = @event.Packetizer::new()
  assert_true(packetizer.push(packet_test_key(A, 1)) is None)
  assert_true(packetizer.push(packet_test_key(B, 1)) is None)
  debug_inspect(
    packetizer.push(packet_test_sync(Report, 7L)),
    content=(
      #|Some(
      #|  {
      #|    timestamp: { sec: 7, usec: 999 },
      #|    events: [
      #|      Key({ timestamp: { sec: 10, usec: 1 }, code: A, state: Pressed }),
      #|      Key({ timestamp: { sec: 10, usec: 1 }, code: B, state: Pressed }),
      #|    ],
      #|  },
      #|)
    ),
  )
}
