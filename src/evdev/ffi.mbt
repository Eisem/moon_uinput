///|
type NativeDevice

///|
#borrow(path)
extern "C" fn native_open(path : Bytes) -> NativeDevice = "mooninput_evdev_open"

///|
#borrow(self)
extern "C" fn NativeDevice::open_error(self : NativeDevice) -> Int = "mooninput_evdev_open_error"

///|
#borrow(self)
extern "C" fn NativeDevice::is_open(self : NativeDevice) -> Bool = "mooninput_evdev_is_open"

///|
#borrow(self)
extern "C" fn NativeDevice::close(self : NativeDevice) -> Int = "mooninput_evdev_close"

///|
#borrow(self, buffer)
extern "C" fn NativeDevice::write_name(
  self : NativeDevice,
  buffer : FixedArray[Byte],
) -> Int = "mooninput_evdev_name"

///|
#borrow(self)
extern "C" fn NativeDevice::id_values(self : NativeDevice) -> FixedArray[Int] = "mooninput_evdev_id"

///|
#borrow(self, buffer)
extern "C" fn NativeDevice::write_capability_bits(
  self : NativeDevice,
  event_type : Int,
  buffer : FixedArray[Byte],
) -> Int = "mooninput_evdev_capability_bits"

///|
#borrow(self)
extern "C" fn NativeDevice::absolute_axis_values(
  self : NativeDevice,
  code : Int,
) -> FixedArray[Int] = "mooninput_evdev_absolute_axis"

///|
#borrow(self)
extern "C" fn NativeDevice::read_values(
  self : NativeDevice,
) -> FixedArray[Int64] = "mooninput_evdev_read"
