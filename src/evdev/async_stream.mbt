///|
/// An independently owned asynchronous view of an evdev descriptor.
///
/// It owns a duplicated file descriptor, so closing the original `Device`
/// does not invalidate this stream. Call `close` when finished. Reads are
/// performed directly by the async runtime: no background reader task is
/// spawned, and cancellation of `next` cannot leave an orphan task.
#warnings("-struct_never_constructed")
priv struct AsyncRecordBuffer {
  frame_size : Int
  buffer : FixedArray[Byte]
  mut filled : Int
}

///|
async fn[E : Error] AsyncRecordBuffer::fill(
  self : AsyncRecordBuffer,
  read : async (FixedArray[Byte], Int, Int) -> Int raise E,
) -> Bool raise E {
  while self.filled < self.frame_size {
    let count = read(self.buffer, self.filled, self.frame_size - self.filled)
    if count == 0 {
      return false
    }
    self.filled += count
  }
  true
}

///|
#warnings("-struct_never_constructed")
pub struct AsyncEventStream {
  source : @raw_fd.RawFd
  priv record : AsyncRecordBuffer
  mut closed : Bool
}

///|
#cfg(not(platform="windows"))
fn async_open_error(path : String, errno : Int) -> @errors.InputError {
  match errno {
    9 => DeviceClosed
    19 => DeviceDisconnected
    1 | 13 => PermissionDenied(path~)
    _ => OpenFailed(path~, errno~)
  }
}

///|
fn async_read_error(errno : Int) -> @errors.InputError {
  match errno {
    9 => DeviceClosed
    19 => DeviceDisconnected
    _ => ReadFailed(errno~)
  }
}

///|
/// Duplicate this open device for independent asynchronous event reading.
///
/// The duplicate transfers ownership to the async runtime even if its
/// registration fails. Reading from this stream and the synchronous device
/// concurrently competes for the same kernel event queue; choose one reader.
#cfg(not(platform="windows"))
pub async fn Device::async_events(self : Device) -> AsyncEventStream {
  let descriptor = self.native.duplicate_fd()
  if descriptor < 0 {
    match -descriptor {
      9 => raise @errors.InputError::DeviceClosed
      19 => raise @errors.InputError::DeviceDisconnected
      errno => raise @errors.InputError::OpenFailed(path=self.path, errno~)
    }
  }
  let source = @raw_fd.RawFd(descriptor) catch {
    @os_error.OSError(errno, ..) => raise async_open_error(self.path, errno)
    err => raise err
  }
  let frame_size = native_event_size()
  {
    source,
    record: {
      frame_size,
      buffer: FixedArray::make(frame_size, b'\x00'),
      filled: 0,
    },
    closed: false,
  }
}

///|
/// Linux-only asynchronous evdev reading is unavailable on Windows native.
#cfg(platform="windows")
#warnings("-unused_async")
pub async fn Device::async_events(self : Device) -> AsyncEventStream {
  let _ = self
  raise @errors.InputError::UnsupportedPlatform
}

///|
/// Close only the stream's duplicated descriptor, not the original device.
pub fn AsyncEventStream::close(self : AsyncEventStream) -> Unit {
  if !self.closed {
    self.closed = true
    self.source.close()
  }
}

///|
/// Await exactly one native `input_event` record, handling short reads.
///
/// At EOF the stream raises `DeviceDisconnected`. Cancellation propagates
/// through the async runtime; any partial record remains buffered so a later
/// call can resume. A single stream must not be read by multiple tasks at once.
pub async fn AsyncEventStream::next_raw(
  self : AsyncEventStream,
) -> @event.RawEvent {
  if self.closed {
    raise @errors.InputError::DeviceClosed
  }
  let complete = self.record.fill((buffer, offset, max_len) => {
    self.source.read(buffer, offset~, max_len~) catch {
      @os_error.OSError(errno, ..) => raise async_read_error(errno)
      err => raise err
    }
  })
  if !complete {
    raise @errors.InputError::DeviceDisconnected
  }
  let values = native_decode_event(self.record.buffer)
  self.record.filled = 0
  {
    timestamp: { sec: values[0], usec: values[1], },
    event_type: values[2].to_int(),
    code: values[3].to_int(),
    value: values[4].to_int(),
  }
}

///|
/// Await and decode one typed input event.
pub async fn AsyncEventStream::next(
  self : AsyncEventStream,
) -> @event.InputEvent {
  @event.decode(self.next_raw())
}

///|
/// Await the next complete SYN_REPORT packet, skipping empty frames.
pub struct AsyncPacketStream {
  events : AsyncEventStream
  packetizer : @event.Packetizer
}

///|
/// Convert this event stream to packetized reading. The returned packet
/// stream takes over use of the event stream; do not read both concurrently.
pub fn AsyncEventStream::packets(self : AsyncEventStream) -> AsyncPacketStream {
  { events: self, packetizer: @event.Packetizer::new(), }
}

///|
/// Close the owned event stream.
pub fn AsyncPacketStream::close(self : AsyncPacketStream) -> Unit {
  self.events.close()
}

///|
/// Await the next nonempty, complete input packet.
pub async fn AsyncPacketStream::next(
  self : AsyncPacketStream,
) -> @event.EventPacket {
  for ;; {
    match self.packetizer.push(self.events.next()) {
      Some(packet) => return packet
      None => ()
    }
  }
}

///|
/// Async packet reader that recovers from `SYN_DROPPED` using a live device.
/// Keep the original device open until this stream is closed: its ioctl handle
/// is required to query pressed keys and absolute-axis state after a drop.
pub struct AsyncSyncedPacketStream {
  packets : AsyncPacketStream
  device : Device
}

///|
/// Create a device-state-aware async packet stream. Like `async_events`,
/// this duplicates the read descriptor; it does not spawn a background task.
pub async fn Device::async_synced_packets(
  self : Device,
) -> AsyncSyncedPacketStream {
  { packets: self.async_events().packets(), device: self, }
}

///|
/// Close the stream's duplicate descriptor, leaving the original device open.
pub fn AsyncSyncedPacketStream::close(self : AsyncSyncedPacketStream) -> Unit {
  self.packets.close()
}

///|
/// Await a complete packet or the current device snapshot after a dropped
/// frame. Cancellation does not prevent a later call from resuming the stream.
pub async fn AsyncSyncedPacketStream::next(
  self : AsyncSyncedPacketStream,
) -> @event.SyncedPacket {
  let packet = self.packets.next()
  @event.synchronize_packet(packet, () => self.device.state())
}
