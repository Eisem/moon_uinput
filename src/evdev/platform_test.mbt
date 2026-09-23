///|
#cfg(platform="windows")
test "evdev reports unsupported platform outside Linux" {
  try @evdev.Device::open("/dev/input/event0") catch {
    UnsupportedPlatform => ()
    error => fail("unexpected error: \{error.describe()}")
  } noraise {
    _ => fail("expected UnsupportedPlatform")
  }
}

///|
test "evdev rejects paths containing NUL before entering C" {
  try @evdev.Device::open("/dev/input/event0\u0000suffix") catch {
    InvalidPath(path~) => inspect(path, content="/dev/input/event0\u0000suffix")
    error => fail("unexpected error: \{error.describe()}")
  } noraise {
    _ => fail("expected InvalidPath")
  }
}

///|
#cfg(all(target="native", not(platform="windows")))
test "evdev handles a closed descriptor predictably" {
  try @evdev.Device::open("/dev/null") catch {
    UnsupportedPlatform => ()
    error => fail("opening /dev/null failed unexpectedly: \{error.describe()}")
  } noraise {
    device => {
      inspect(device.is_open(), content="true")
      device.close()
      inspect(device.is_open(), content="false")
      try device.name() catch {
        DeviceClosed => ()
        error => fail("unexpected name error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceClosed from name")
      }
      try device.id() catch {
        DeviceClosed => ()
        error => fail("unexpected ID error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceClosed from id")
      }
      try device.capabilities() catch {
        DeviceClosed => ()
        error => fail("unexpected capabilities error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceClosed from capabilities")
      }
      try device.read_raw() catch {
        DeviceClosed => ()
        error => fail("unexpected error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceClosed")
      }
      try device.packets().next() catch {
        DeviceClosed => ()
        error => fail("unexpected packet stream error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceClosed from packet stream")
      }
    }
  }
}

///|
#cfg(all(target="native", not(platform="windows")))
test "packet stream propagates disconnection without yielding partial frames" {
  try @evdev.Device::open("/dev/null") catch {
    UnsupportedPlatform => ()
    error => fail("opening /dev/null failed unexpectedly: \{error.describe()}")
  } noraise {
    device => {
      try device.packets().next() catch {
        DeviceDisconnected => ()
        error => fail("unexpected packet stream error: \{error.describe()}")
      } noraise {
        _ => fail("expected DeviceDisconnected from /dev/null packet stream")
      }
      device.close()
    }
  }
}
