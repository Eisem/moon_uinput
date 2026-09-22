///|
/// Stable device identity returned by Linux `EVIOCGID`.
pub(all) struct DeviceId {
  bus_type : Int
  vendor : Int
  product : Int
  version : Int
} derive(Debug, Eq)

///|
pub extend DeviceId with Debug::{to_repr}

///|
pub extend DeviceId with Eq::{equal, not_equal}

///|
/// An open evdev device. The underlying file descriptor is also closed by a
/// native finalizer if callers forget to call `close` explicitly.
pub struct Device {
  native : NativeDevice
  path : String
}

///|
fn raise_open_error(
  path : String,
  errno : Int,
) -> Unit raise @errors.InputError {
  match errno {
    22 => raise InvalidPath(path~)
    1 | 13 => raise PermissionDenied(path~)
    2 | 19 => raise DeviceNotFound(path~)
    38 => raise UnsupportedPlatform
    _ => raise OpenFailed(path~, errno~)
  }
}

///|
fn raise_ioctl_error(
  operation : String,
  errno : Int,
) -> Unit raise @errors.InputError {
  match errno {
    9 => raise DeviceClosed
    19 => raise DeviceDisconnected
    _ => raise IoctlFailed(operation~, errno~)
  }
}

///|
/// Open a Linux `/dev/input/eventX` node for reading.
pub fn Device::open(path : String) -> Device raise @errors.InputError {
  let path_bytes = @utf8.encode(path)
  if path_bytes.find(b"\x00") is Some(_) {
    raise InvalidPath(path~)
  }
  let native = native_open(path_bytes)
  if !native.is_open() {
    raise_open_error(path, native.open_error())
  }
  { native, path, }
}

///|
pub fn Device::path(self : Device) -> String {
  self.path
}

///|
pub fn Device::is_open(self : Device) -> Bool {
  self.native.is_open()
}

///|
/// Close the device. Repeated calls are safe.
pub fn Device::close(self : Device) -> Unit raise @errors.InputError {
  let errno = self.native.close()
  if errno != 0 {
    raise CloseFailed(errno~)
  }
}

///|
/// Query the human-readable device name with `EVIOCGNAME`.
pub fn Device::name(self : Device) -> String raise @errors.InputError {
  let buffer : FixedArray[Byte] = FixedArray::make(256, b'\x00')
  let result = self.native.write_name(buffer)
  if result < 0 {
    raise_ioctl_error("EVIOCGNAME", -result)
  }
  @utf8.decode_lossy(Bytes::makei(result, index => buffer[index]))
}

///|
/// Query bus, vendor, product, and version with `EVIOCGID`.
pub fn Device::id(self : Device) -> DeviceId raise @errors.InputError {
  let values = self.native.id_values()
  if values[0] != 0 {
    raise_ioctl_error("EVIOCGID", values[1])
  }
  {
    bus_type: values[2],
    vendor: values[3],
    product: values[4],
    version: values[5],
  }
}

///|
/// Read one ABI-normalized raw event from the device.
pub fn Device::read_raw(
  self : Device,
) -> @event.RawEvent raise @errors.InputError {
  let values = self.native.read_values()
  match values[0] {
    1L =>
      {
        timestamp: { sec: values[2], usec: values[3], },
        event_type: values[4].to_int(),
        code: values[5].to_int(),
        value: values[6].to_int(),
      }
    0L => raise DeviceDisconnected
    _ =>
      match values[1] {
        9L => raise DeviceClosed
        19L => raise DeviceDisconnected
        errno => raise ReadFailed(errno=errno.to_int())
      }
  }
}

///|
/// Read and decode one typed input event.
pub fn Device::read_event(
  self : Device,
) -> @event.InputEvent raise @errors.InputError {
  @event.decode(self.read_raw())
}

///|
/// Create a blocking typed event stream for this device.
pub fn Device::events(self : Device) -> EventStream {
  { device: self, }
}
