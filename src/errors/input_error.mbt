///|
/// Errors produced by evdev and, in later phases, uinput operations.
pub(all) suberror InputError {
  InvalidPath(path~ : String)
  PermissionDenied(path~ : String)
  DeviceNotFound(path~ : String)
  OpenFailed(path~ : String, errno~ : Int)
  DeviceClosed
  DeviceDisconnected
  AlreadyGrabbed(path~ : String)
  NotGrabbed(path~ : String)
  UnsupportedPlatform
  DiscoveryFailed(directory~ : String, reason~ : String)
  IoctlFailed(operation~ : String, errno~ : Int)
  ReadFailed(errno~ : Int)
  CloseFailed(errno~ : Int)
  InvalidVirtualDeviceConfig(reason~ : String)
  VirtualDeviceFailed(operation~ : String, errno~ : Int)
} derive(Debug, Eq)

///|
pub extend InputError with Debug::{to_repr}

///|
pub extend InputError with Eq::{equal, not_equal}

///|
/// Return a user-facing explanation while preserving structured error data.
pub fn InputError::describe(self : InputError) -> String {
  match self {
    InvalidPath(_) => "Input device path contains an embedded NUL byte"
    PermissionDenied(path~) => "Permission denied: \{path}"
    DeviceNotFound(path~) => "Input device not found: \{path}"
    OpenFailed(path~, errno~) => "Opening \{path} failed with errno \{errno}"
    DeviceClosed => "Input device is closed"
    DeviceDisconnected => "Input device disconnected"
    AlreadyGrabbed(path~) => "Input device is already grabbed: \{path}"
    NotGrabbed(path~) => "Input device is not grabbed: \{path}"
    UnsupportedPlatform => "MoonInput evdev requires Linux"
    DiscoveryFailed(directory~, reason~) =>
      "Discovering input devices in \{directory} failed: \{reason}"
    IoctlFailed(operation~, errno~) => "\{operation} failed with errno \{errno}"
    ReadFailed(errno~) => "Reading input event failed with errno \{errno}"
    CloseFailed(errno~) => "Closing input device failed with errno \{errno}"
    InvalidVirtualDeviceConfig(reason~) =>
      "Invalid virtual device configuration: \{reason}"
    VirtualDeviceFailed(operation~, errno~) =>
      "Virtual device \{operation} failed with errno \{errno}"
  }
}
