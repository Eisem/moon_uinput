///|
#cfg(not(platform="windows"))
test "async open errors preserve structured errno semantics" {
  debug_inspect(
    async_open_error("/dev/input/event4", 9),
    content="DeviceClosed",
  )
  debug_inspect(
    async_open_error("/dev/input/event4", 19),
    content="DeviceDisconnected",
  )
  debug_inspect(
    async_open_error("/dev/input/event4", 13),
    content="PermissionDenied(path=\"/dev/input/event4\")",
  )
  debug_inspect(
    async_open_error("/dev/input/event4", 16),
    content="OpenFailed(path=\"/dev/input/event4\", errno=16)",
  )
}

///|
#cfg(not(platform="windows"))
test "async read errors match synchronous read errors" {
  debug_inspect(async_read_error(9), content="DeviceClosed")
  debug_inspect(async_read_error(19), content="DeviceDisconnected")
  debug_inspect(async_read_error(5), content="ReadFailed(errno=5)")
}

///|
async test "partial async record survives cancellation and resumes" {
  let record : AsyncRecordBuffer = {
    frame_size: 4,
    buffer: FixedArray::make(4, b'\x00'),
    filled: 0,
  }
  let mut calls = 0
  let read = (buffer : FixedArray[Byte], offset : Int, _max_len : Int) => {
    if _max_len < 0 {
      raise async_read_error(-1)
    }
    calls += 1
    match calls {
      1 => {
        buffer[offset] = b'a'
        buffer[offset + 1] = b'b'
        2
      }
      2 => {
        @async.sleep(10000)
        0
      }
      _ => {
        buffer[offset] = b'c'
        buffer[offset + 1] = b'd'
        2
      }
    }
  }
  @async.with_task_group <| group => {
    let pending = group.spawn() <| () => {
      let result = @async.handle_cancellation(() => record.fill(read))
      assert_true(result is None)
    }
    @async.pause()
    pending.cancel()
    pending.wait()
    inspect(record.filled, content="2")
    assert_true(record.fill(read))
    inspect(record.filled, content="4")
    inspect(record.buffer.unsafe_reinterpret_as_bytes(), content="b\"abcd\"")
  }
}
