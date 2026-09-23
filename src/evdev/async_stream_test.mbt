///|
#cfg(platform="windows")
async test "Windows does not open Linux evdev paths in async programs" {
  try @evdev.Device::open("/dev/input/event0") catch {
    UnsupportedPlatform => ()
    _ => fail("expected UnsupportedPlatform on Windows")
  } noraise {
    device => {
      device.close()
      fail("Windows unexpectedly opened an evdev device")
    }
  }
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "async stream owns duplicate and returns EOF without hardware" {
  let device = @evdev.Device::open("/dev/null")
  let stream = device.async_events()
  device.close()
  try stream.next_raw() catch {
    @errors.InputError::DeviceDisconnected => ()
    _ => fail("expected DeviceDisconnected from asynchronous /dev/null")
  } noraise {
    _ => fail("expected an EOF error")
  }
  stream.close()
}

///|
#cfg(all(target="native", not(platform="windows")))
async test "async event stream rejects a closed source" {
  let device = @evdev.Device::open("/dev/null")
  device.close()
  try device.async_events() catch {
    @errors.InputError::DeviceClosed => ()
    _ => fail("expected DeviceClosed from asynchronous open")
  } noraise {
    stream => {
      stream.close()
      fail("expected an error from asynchronous open")
    }
  }
}
