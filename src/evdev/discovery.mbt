///|
/// Metadata collected from one readable evdev node.
pub(all) struct DeviceInfo {
  path : String
  name : String
  id : DeviceId
} derive(Debug, Eq)

///|
pub extend DeviceInfo with Debug::{to_repr}

///|
pub extend DeviceInfo with Eq::{equal, not_equal}

///|
/// One entry from device discovery. An inaccessible or malformed device is
/// retained with its structured error so it cannot hide later devices.
pub(all) enum DeviceDiscoveryEntry {
  Available(DeviceInfo)
  Unavailable(path~ : String, error~ : @errors.InputError)
} derive(Debug, Eq)

///|
pub extend DeviceDiscoveryEntry with Debug::{to_repr}

///|
pub extend DeviceDiscoveryEntry with Eq::{equal, not_equal}

///|
fn event_node_number(name : String) -> Int? {
  guard name.has_prefix("event") else { return None }
  let suffix = name[5:]
  if suffix.length() == 0 || suffix.length() > 9 {
    return None
  }
  let mut number = 0
  for char in suffix {
    if char < '0' || char > '9' {
      return None
    }
    number = number * 10 + char.to_int() - '0'.to_int()
  }
  Some(number)
}

///|
fn sorted_event_paths(
  directory : String,
  entries : ArrayView[String],
) -> Array[String] {
  let numbered : Array[(Int, String)] = []
  for name in entries {
    guard event_node_number(name) is Some(number) else { continue }
    numbered.push((number, name))
  }
  numbered.sort_by(fn(left, right) {
    let by_number = left.0 - right.0
    if by_number != 0 {
      by_number
    } else {
      left.1.compare(right.1)
    }
  })
  let separator = if directory.has_suffix("/") { "" } else { "/" }
  numbered.map(entry => "\{directory}\{separator}\{entry.1}")
}

///|
/// Enumerate actual `eventN` entries in a directory and return them in numeric
/// order. No event number is guessed. Directory failures are reported as a
/// structured `DiscoveryFailed` error.
pub fn list_device_paths(
  directory? : String = "/dev/input",
) -> Array[String] raise @errors.InputError {
  let entries = @fs.read_dir(directory) catch {
    IOError(reason) => raise DiscoveryFailed(directory~, reason~)
  }
  sorted_event_paths(directory, entries)
}

///|
fn[T] collect_probe_results(
  paths : Array[String],
  probe : (String) -> T raise @errors.InputError,
) -> Array[Result[T, @errors.InputError]] {
  paths.map(fn(path) { Ok(probe(path)) catch { error => Err(error) } })
}

///|
fn read_device_info(path : String) -> DeviceInfo raise @errors.InputError {
  let device = Device::open(path)
  errdefer (device.close() catch { _ => () })
  let info = { path, name: device.name(), id: device.id(), }
  device.close()
  info
}

///|
/// Discover and inspect every evdev node. Per-device failures are returned as
/// entries instead of aborting the scan, so callers can display permission or
/// hot-unplug errors while continuing with remaining devices.
pub fn discover_devices(
  directory? : String = "/dev/input",
) -> Array[DeviceDiscoveryEntry] raise @errors.InputError {
  let paths = list_device_paths(directory~)
  let results = collect_probe_results(paths, read_device_info)
  Array::makei(paths.length(), fn(index) {
    match results[index] {
      Ok(info) => Available(info)
      Err(error) => Unavailable(path=paths[index], error~)
    }
  })
}
