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
    @errors.InputError::OpenFailed(path="/dev/input/event4", errno=16).describe(),
    content="Opening /dev/input/event4 failed with errno 16",
  )
}
