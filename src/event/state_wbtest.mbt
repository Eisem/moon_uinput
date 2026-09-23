///|
test "sync recovery samples replacement state after dropped frames" {
  let packet : EventPacket = {
    timestamp: { sec: 2L, usec: 0L, },
    events: [Sync({ timestamp: { sec: 1L, usec: 0L, }, code: Dropped, })],
  }
  let state : DeviceState = {
    pressed_keys: [A],
    absolute_axes: [{ axis: X, value: 512, }],
  }
  debug_inspect(
    synchronize_packet(packet, () => state),
    content=(
      #|Recovered({ pressed_keys: [A], absolute_axes: [{ axis: X, value: 512 }] })
    ),
  )
}

///|
test "normal packets bypass the replacement state source" {
  let packet : EventPacket = {
    timestamp: { sec: 2L, usec: 0L, },
    events: [
      Key({ timestamp: { sec: 1L, usec: 0L, }, code: A, state: Pressed, }),
    ],
  }
  debug_inspect(
    synchronize_packet(packet, () => raise DeviceClosed),
    content=(
      #|Events(
      #|  {
      #|    timestamp: { sec: 2, usec: 0 },
      #|    events: [Key({ timestamp: { sec: 1, usec: 0 }, code: A, state: Pressed })],
      #|  },
      #|)
    ),
  )
}

///|
test "recovery preserves snapshot source errors" {
  let packet : EventPacket = {
    timestamp: { sec: 2L, usec: 0L, },
    events: [Sync({ timestamp: { sec: 1L, usec: 0L, }, code: Dropped, })],
  }
  try synchronize_packet(packet, () => raise DeviceClosed) catch {
    DeviceClosed => ()
    _ => fail("unexpected recovery error")
  } noraise {
    _ => fail("expected recovery state source error")
  }
}
