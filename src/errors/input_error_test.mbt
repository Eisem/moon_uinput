///|
test "input errors have actionable messages" {
  inspect(
    @errors.InputError::InvalidPath(path="bad\u0000path").describe(),
    content="Input device path contains an embedded NUL byte",
  )
  inspect(
    @errors.InputError::PermissionDenied(path="/dev/input/event4").describe(),
    content="Permission denied: /dev/input/event4",
  )
  inspect(
    @errors.InputError::DeviceDisconnected.describe(),
    content="Input device disconnected",
  )
  inspect(
    @errors.InputError::DeviceClosed.describe(),
    content="Input device is closed",
  )
  inspect(
    @errors.InputError::AlreadyGrabbed(path="/dev/input/event4").describe(),
    content="Input device is already grabbed: /dev/input/event4",
  )
  inspect(
    @errors.InputError::NotGrabbed(path="/dev/input/event4").describe(),
    content="Input device is not grabbed: /dev/input/event4",
  )
  inspect(
    @errors.InputError::InvalidOutputEvent(event_type=99, code=-1).describe(),
    content="Invalid Linux input event type/code: 99/-1",
  )
  inspect(
    @errors.InputError::UnsupportedOutputCapability(event_type=1, code=31).describe(),
    content="Virtual device does not advertise event type/code: 1/31",
  )
  inspect(
    @errors.InputError::OpenFailed(path="/dev/input/event4", errno=16).describe(),
    content="Opening /dev/input/event4 failed with errno 16",
  )
  inspect(
    @errors.InputError::DiscoveryFailed(
      directory="/dev/input",
      reason="directory missing",
    ).describe(),
    content="Discovering input devices in /dev/input failed: directory missing",
  )
}
