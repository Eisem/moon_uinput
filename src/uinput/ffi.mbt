///|
type NativeVirtualDevice

///|
extern "C" fn native_create() -> NativeVirtualDevice = "mooninput_uinput_open"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::error(self : NativeVirtualDevice) -> Int = "mooninput_uinput_error"

///|
#borrow(self, name)
extern "C" fn NativeVirtualDevice::setup(
  self : NativeVirtualDevice,
  name : Bytes,
  bus : Int,
  vendor : Int,
  product : Int,
  version : Int,
) -> Int = "mooninput_uinput_setup"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::set_capability(
  self : NativeVirtualDevice,
  event_type : Int,
  code : Int,
) -> Int = "mooninput_uinput_set_capability"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::set_absolute(
  self : NativeVirtualDevice,
  code : Int,
  minimum : Int,
  maximum : Int,
  fuzz : Int,
  flat : Int,
  resolution : Int,
) -> Int = "mooninput_uinput_set_absolute"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::create(self : NativeVirtualDevice) -> Int = "mooninput_uinput_create"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::emit(
  self : NativeVirtualDevice,
  event_type : Int,
  code : Int,
  value : Int,
) -> Int = "mooninput_uinput_emit"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::close(self : NativeVirtualDevice) -> Int = "mooninput_uinput_close"

///|
#borrow(self)
extern "C" fn NativeVirtualDevice::is_open(self : NativeVirtualDevice) -> Bool = "mooninput_uinput_is_open"
