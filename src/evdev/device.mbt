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
fn raise_grab_error(
  path : String,
  errno : Int,
  grabbing : Bool,
) -> Unit raise @errors.InputError {
  match errno {
    9 => raise DeviceClosed
    19 => raise DeviceDisconnected
    114 if grabbing => raise AlreadyGrabbed(path~)
    22 if !grabbing => raise NotGrabbed(path~)
    _ => raise IoctlFailed(operation="EVIOCGRAB", errno~)
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
/// Exclusively grab this input device until `ungrab` or `close`.
///
/// Repeating `grab` raises `AlreadyGrabbed`. The kernel releases the grab when
/// the descriptor closes, including when its native finalizer runs.
pub fn Device::grab(self : Device) -> Unit raise @errors.InputError {
  let errno = self.native.grab(true)
  if errno != 0 {
    raise_grab_error(self.path, errno, true)
  }
}

///|
/// Release a grab acquired with `grab`.
///
/// Repeating `ungrab` raises `NotGrabbed`; a closed or disconnected device
/// raises the corresponding structured error.
pub fn Device::ungrab(self : Device) -> Unit raise @errors.InputError {
  let errno = self.native.grab(false)
  if errno != 0 {
    raise_grab_error(self.path, errno, false)
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
fn NativeDevice::capability_bitmap(
  self : NativeDevice,
  event_type : Int,
) -> Bytes raise @errors.InputError {
  // 1024 bits covers every current evdev code family while retaining room for
  // future kernel additions. The ioctl reports the actual number of bytes used.
  let buffer : FixedArray[Byte] = FixedArray::make(128, b'\x00')
  let length = self.write_capability_bits(event_type, buffer)
  if length < 0 {
    raise_ioctl_error("EVIOCGBIT", -length)
  }
  Bytes::makei(length, index => buffer[index])
}

///|
fn NativeDevice::absolute_axis_info(
  self : NativeDevice,
  axis : @codes.AbsoluteAxis,
) -> AbsoluteAxisInfo raise @errors.InputError {
  let values = self.absolute_axis_values(axis.to_linux())
  if values[0] != 0 {
    raise_ioctl_error("EVIOCGABS(\{axis.to_linux()})", values[1])
  }
  {
    value: values[2],
    minimum: values[3],
    maximum: values[4],
    fuzz: values[5],
    flat: values[6],
    resolution: values[7],
  }
}

///|
fn NativeDevice::key_state_bitmap(
  self : NativeDevice,
) -> Bytes raise @errors.InputError {
  let buffer : FixedArray[Byte] = FixedArray::make(96, b'\x00')
  let length = self.write_key_state(buffer)
  if length < 0 {
    raise_ioctl_error("EVIOCGKEY", -length)
  }
  Bytes::makei(length, index => buffer[index])
}

///|
/// Query typed event, key, axis, switch, and LED capabilities.
pub fn Device::capabilities(
  self : Device,
) -> DeviceCapabilities raise @errors.InputError {
  let decoded = decode_capability_bitmaps(
    self.native.capability_bitmap(0),
    self.native.capability_bitmap(1),
    self.native.capability_bitmap(2),
    self.native.capability_bitmap(3),
    self.native.capability_bitmap(5),
    self.native.capability_bitmap(17),
  )
  let absolute_axes : Array[AbsoluteAxisCapability] = []
  for entry in decoded.absolute_axes {
    absolute_axes.push({
      axis: entry.axis,
      info: Some(self.native.absolute_axis_info(entry.axis)),
    })
  }
  {
    event_types: decoded.event_types,
    keys: decoded.keys,
    relative_axes: decoded.relative_axes,
    absolute_axes,
    switches: decoded.switches,
    leds: decoded.leds,
  }
}

///|
fn snapshot_device_state(
  key_state : () -> Bytes raise @errors.InputError,
  absolute_axis_bitmap : () -> Bytes raise @errors.InputError,
  absolute_axis_info : (@codes.AbsoluteAxis) -> AbsoluteAxisInfo raise @errors.InputError,
) -> @event.DeviceState raise @errors.InputError {
  // Two base ioctls plus one live-value ioctl per axis; a full capabilities
  // query here would add five unrelated EVIOCGBIT calls on every recovery.
  let pressed_keys = decode_keys(key_state())
  let absolute_axes : Array[@event.AbsoluteAxisState] = []
  for axis in decode_absolute_axes(absolute_axis_bitmap()) {
    let info = absolute_axis_info(axis.axis)
    absolute_axes.push({ axis: axis.axis, value: info.value, })
  }
  { pressed_keys, absolute_axes, }
}

///|
/// Query pressed keys and current absolute-axis values from the kernel.
///
/// This snapshot is intended for resynchronizing after `SYN_DROPPED`. It reads
/// the key bitmap, the absolute-axis capability bitmap, and then each axis's
/// current value; it does not query unrelated capability families.
pub fn Device::state(
  self : Device,
) -> @event.DeviceState raise @errors.InputError {
  snapshot_device_state(
    () => self.native.key_state_bitmap(),
    () => self.native.capability_bitmap(3),
    axis => self.native.absolute_axis_info(axis),
  )
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

///|
/// Create a blocking stream that yields complete `SYN_REPORT` packets.
///
/// Empty frames are skipped. Use `events()` when individual sync markers are
/// needed. If reading raises an I/O error, an incomplete frame is not returned;
/// it remains pending if the caller retries the stream.
pub fn Device::packets(self : Device) -> DevicePacketStream {
  { device: self, packetizer: @event.Packetizer::new(), }
}

///|
/// Create a packet stream that queries current device state after `SYN_DROPPED`.
pub fn Device::synced_packets(self : Device) -> SyncedPacketStream {
  { packets: self.packets(), device: self, }
}
