///|
pub(all) struct AbsoluteAxisSetup {
  axis : @codes.AbsoluteAxis
  minimum : Int
  maximum : Int
  fuzz : Int
  flat : Int
  resolution : Int
} derive(Debug, Eq)

///|
pub extend AbsoluteAxisSetup with Debug::{to_repr}

///|
pub extend AbsoluteAxisSetup with Eq::{equal, not_equal}

///|
pub struct VirtualDeviceBuilder {
  name : String
  mut bus : Int
  mut vendor : Int
  mut product : Int
  mut version : Int
  keys : Array[@codes.KeyCode]
  relative_axes : Array[@codes.RelativeAxis]
  absolute_axes : Array[AbsoluteAxisSetup]
}

///|
pub struct VirtualDevice {
  native : NativeVirtualDevice
  keys : Array[Int]
  relative_axes : Array[Int]
  absolute_axes : Array[Int]
}

///|
pub fn VirtualDeviceBuilder::new(
  name? : String = "MoonInput",
) -> VirtualDeviceBuilder {
  {
    name,
    bus: 0x03,
    vendor: 0x1209,
    product: 0x0001,
    version: 1,
    keys: [],
    relative_axes: [],
    absolute_axes: [],
  }
}

///|
pub fn VirtualDeviceBuilder::identity(
  self : VirtualDeviceBuilder,
  bus : Int,
  vendor : Int,
  product : Int,
  version : Int,
) -> VirtualDeviceBuilder {
  self.bus = bus
  self.vendor = vendor
  self.product = product
  self.version = version
  self
}

///|
pub fn VirtualDeviceBuilder::key(
  self : VirtualDeviceBuilder,
  key : @codes.KeyCode,
) -> VirtualDeviceBuilder {
  if !self.keys.contains(key) {
    self.keys.push(key)
  }
  self
}

///|
pub fn VirtualDeviceBuilder::relative_axis(
  self : VirtualDeviceBuilder,
  axis : @codes.RelativeAxis,
) -> VirtualDeviceBuilder {
  if !self.relative_axes.contains(axis) {
    self.relative_axes.push(axis)
  }
  self
}

///|
pub fn VirtualDeviceBuilder::absolute_axis(
  self : VirtualDeviceBuilder,
  setup : AbsoluteAxisSetup,
) -> VirtualDeviceBuilder {
  if !self.absolute_axes.any(fn(existing) { existing.axis == setup.axis }) {
    self.absolute_axes.push(setup)
  }
  self
}

///|
pub fn VirtualDeviceBuilder::validate(
  self : VirtualDeviceBuilder,
) -> Unit raise @errors.InputError {
  let name = @utf8.encode(self.name)
  if self.name.is_empty() ||
    name.length() >= 80 ||
    name.find(b"\x00") is Some(_) {
    raise InvalidVirtualDeviceConfig(
      reason="name must be 1–79 UTF-8 bytes without NUL",
    )
  }
  for value in [self.bus, self.vendor, self.product, self.version] {
    if value < 0 || value > 65535 {
      raise InvalidVirtualDeviceConfig(reason="identity fields must fit uint16")
    }
  }
  if self.keys.is_empty() &&
    self.relative_axes.is_empty() &&
    self.absolute_axes.is_empty() {
    raise InvalidVirtualDeviceConfig(
      reason="at least one input capability is required",
    )
  }
  for key in self.keys {
    let code = key.to_linux()
    if code < 0 || code > 0x2ff {
      raise InvalidVirtualDeviceConfig(
        reason="key code is outside the Linux input range",
      )
    }
  }
  for axis in self.relative_axes {
    let code = axis.to_linux()
    if code < 0 || code > 0x0f {
      raise InvalidVirtualDeviceConfig(
        reason="relative axis code is outside the Linux input range",
      )
    }
  }
  for setup in self.absolute_axes {
    let code = setup.axis.to_linux()
    if code < 0 ||
      code > 0x3f ||
      setup.minimum >= setup.maximum ||
      setup.fuzz < 0 ||
      setup.flat < 0 ||
      setup.resolution < 0 {
      raise InvalidVirtualDeviceConfig(
        reason="absolute axis range or metadata is invalid",
      )
    }
  }
}

///|
fn check_errno(
  operation : String,
  errno : Int,
) -> Unit raise @errors.InputError {
  if errno != 0 {
    match errno {
      1 | 13 => raise PermissionDenied(path="/dev/uinput")
      2 | 19 | 38 => raise DeviceNotFound(path="/dev/uinput")
      9 => raise DeviceClosed
      _ => raise VirtualDeviceFailed(operation~, errno~)
    }
  }
}

///|
/// Validate and create the configured Linux uinput device. Duplicate
/// capabilities are collapsed; the first absolute-axis setup wins.
pub fn VirtualDeviceBuilder::create(
  self : VirtualDeviceBuilder,
) -> VirtualDevice raise @errors.InputError {
  self.validate()
  let native = native_create()
  check_errno("open", native.error())
  let configured = native.setup(
    @utf8.encode(self.name),
    self.bus,
    self.vendor,
    self.product,
    self.version,
  )
  if configured != 0 {
    ignore(native.close())
    check_errno("UI_DEV_SETUP", configured)
  }
  for key in self.keys {
    let err = native.set_capability(1, key.to_linux())
    if err != 0 {
      ignore(native.close())
      check_errno("UI_SET_KEYBIT", err)
    }
  }
  for axis in self.relative_axes {
    let err = native.set_capability(2, axis.to_linux())
    if err != 0 {
      ignore(native.close())
      check_errno("UI_SET_RELBIT", err)
    }
  }
  for setup in self.absolute_axes {
    let err = native.set_capability(3, setup.axis.to_linux())
    if err != 0 {
      ignore(native.close())
      check_errno("UI_SET_ABSBIT", err)
    }
    let err = native.set_absolute(
      setup.axis.to_linux(),
      setup.minimum,
      setup.maximum,
      setup.fuzz,
      setup.flat,
      setup.resolution,
    )
    if err != 0 {
      ignore(native.close())
      check_errno("UI_ABS_SETUP", err)
    }
  }
  let err = native.create()
  if err != 0 {
    ignore(native.close())
  }
  check_errno("UI_DEV_CREATE", err)
  let keys : Array[Int] = []
  let relative_axes : Array[Int] = []
  let absolute_axes : Array[Int] = []
  for key in self.keys {
    keys.push(key.to_linux())
  }
  for axis in self.relative_axes {
    relative_axes.push(axis.to_linux())
  }
  for setup in self.absolute_axes {
    absolute_axes.push(setup.axis.to_linux())
  }
  { native, keys, relative_axes, absolute_axes, }
}

///|
/// Whether the virtual device descriptor remains open.
pub fn VirtualDevice::is_open(self : VirtualDevice) -> Bool {
  self.native.is_open()
}

///|
/// Kernel sysfs name (usually `inputN`) assigned to this created device.
/// It can be used to locate the device's own event node for integration tests
/// and to avoid feedback when input and output devices are both monitored.
pub fn VirtualDevice::sysname(
  self : VirtualDevice,
) -> String raise @errors.InputError {
  let buffer : FixedArray[Byte] = FixedArray::make(128, b'\x00')
  let length = self.native.write_sysname(buffer)
  if length < 0 {
    check_errno("UI_GET_SYSNAME", -length)
  }
  @utf8.decode_lossy(Bytes::makei(length, index => buffer[index]))
}

///|
/// Destroy the kernel device and close its descriptor. Repeated calls are safe.
pub fn VirtualDevice::close(
  self : VirtualDevice,
) -> Unit raise @errors.InputError {
  check_errno("close", self.native.close())
}
