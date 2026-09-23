#include "moonbit.h"

#include <errno.h>
#include <stdint.h>
#include <string.h>

#ifdef __linux__
#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>
#endif

typedef struct {
  int fd;
  int open_error;
} mooninput_evdev_device;

static void mooninput_evdev_finalize(void *self) {
  mooninput_evdev_device *device = (mooninput_evdev_device *)self;
#ifdef __linux__
  if (device->fd >= 0) {
    close(device->fd);
    device->fd = -1;
  }
#else
  (void)device;
#endif
}

MOONBIT_FFI_EXPORT mooninput_evdev_device *
mooninput_evdev_open(moonbit_bytes_t path) {
  mooninput_evdev_device *device = moonbit_make_external_object(
      mooninput_evdev_finalize, sizeof(mooninput_evdev_device));
  device->fd = -1;
  device->open_error = 0;
#ifdef __linux__
  uint32_t path_len = Moonbit_array_length(path);
  if (memchr(path, '\0', path_len) != NULL) {
    device->open_error = EINVAL;
    return device;
  }
  char *path_z = (char *)libc_malloc((size_t)path_len + 1);
  if (path_z == NULL) {
    device->open_error = ENOMEM;
    return device;
  }
  memcpy(path_z, path, path_len);
  path_z[path_len] = '\0';
  device->fd = open(path_z, O_RDONLY | O_CLOEXEC);
  device->open_error = device->fd < 0 ? errno : 0;
  libc_free(path_z);
#else
  (void)path;
  device->open_error = 38;
#endif
  return device;
}

MOONBIT_FFI_EXPORT int32_t
mooninput_evdev_open_error(mooninput_evdev_device *device) {
  return device->open_error;
}

MOONBIT_FFI_EXPORT int32_t
mooninput_evdev_is_open(mooninput_evdev_device *device) {
  return device->fd >= 0;
}

MOONBIT_FFI_EXPORT int32_t
mooninput_evdev_close(mooninput_evdev_device *device) {
#ifdef __linux__
  if (device->fd < 0) {
    return 0;
  }
  int fd = device->fd;
  device->fd = -1;
  if (close(fd) < 0) {
    return errno;
  }
  return 0;
#else
  (void)device;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t
mooninput_evdev_name(mooninput_evdev_device *device, uint8_t *buffer) {
#ifdef __linux__
  if (device->fd < 0) {
    return -EBADF;
  }
  uint32_t capacity = Moonbit_array_length(buffer);
  if (capacity == 0) {
    return -EINVAL;
  }
  memset(buffer, 0, capacity);
  if (ioctl(device->fd, EVIOCGNAME(capacity), buffer) < 0) {
    return -errno;
  }
  return (int32_t)strnlen((const char *)buffer, capacity);
#else
  (void)buffer;
  return -38;
#endif
}

MOONBIT_FFI_EXPORT int32_t *
mooninput_evdev_id(mooninput_evdev_device *device) {
  int32_t *result = moonbit_make_int32_array(6, 0);
#ifdef __linux__
  struct input_id id;
  if (device->fd < 0) {
    result[0] = -1;
    result[1] = EBADF;
    return result;
  }
  if (ioctl(device->fd, EVIOCGID, &id) < 0) {
    result[0] = -1;
    result[1] = errno;
    return result;
  }
  result[2] = id.bustype;
  result[3] = id.vendor;
  result[4] = id.product;
  result[5] = id.version;
#else
  result[0] = -1;
  result[1] = 38;
#endif
  return result;
}

MOONBIT_FFI_EXPORT int32_t mooninput_evdev_capability_bits(
    mooninput_evdev_device *device, int32_t event_type, uint8_t *buffer) {
#ifdef __linux__
  if (device->fd < 0) {
    return -EBADF;
  }
  uint32_t capacity = Moonbit_array_length(buffer);
  if (capacity == 0) {
    return -EINVAL;
  }
  memset(buffer, 0, capacity);
  int result = ioctl(device->fd, EVIOCGBIT(event_type, capacity), buffer);
  return result < 0 ? -errno : result;
#else
  (void)device;
  (void)event_type;
  (void)buffer;
  return -38;
#endif
}

MOONBIT_FFI_EXPORT int32_t *
mooninput_evdev_absolute_axis(mooninput_evdev_device *device, int32_t code) {
  int32_t *result = moonbit_make_int32_array(8, 0);
#ifdef __linux__
  struct input_absinfo info;
  if (device->fd < 0) {
    result[0] = -1;
    result[1] = EBADF;
    return result;
  }
  if (ioctl(device->fd, EVIOCGABS(code), &info) < 0) {
    result[0] = -1;
    result[1] = errno;
    return result;
  }
  result[2] = info.value;
  result[3] = info.minimum;
  result[4] = info.maximum;
  result[5] = info.fuzz;
  result[6] = info.flat;
  result[7] = info.resolution;
#else
  (void)device;
  (void)code;
  result[0] = -1;
  result[1] = 38;
#endif
  return result;
}

MOONBIT_FFI_EXPORT int32_t mooninput_evdev_key_state(
    mooninput_evdev_device *device, uint8_t *buffer) {
#ifdef __linux__
  if (device->fd < 0) {
    return -EBADF;
  }
  uint32_t capacity = Moonbit_array_length(buffer);
  if (capacity == 0) {
    return -EINVAL;
  }
  memset(buffer, 0, capacity);
  int result = ioctl(device->fd, EVIOCGKEY(capacity), buffer);
  return result < 0 ? -errno : result;
#else
  (void)device;
  (void)buffer;
  return -38;
#endif
}

MOONBIT_FFI_EXPORT int64_t *
mooninput_evdev_read(mooninput_evdev_device *device) {
  int64_t *result = moonbit_make_int64_array(7, 0);
#ifdef __linux__
  struct input_event event;
  ssize_t count;
  if (device->fd < 0) {
    result[0] = -1;
    result[1] = EBADF;
    return result;
  }
  do {
    count = read(device->fd, &event, sizeof(event));
  } while (count < 0 && errno == EINTR);
  if (count == 0) {
    result[0] = 0;
    return result;
  }
  if (count < 0) {
    result[0] = -1;
    result[1] = errno;
    return result;
  }
  if ((size_t)count != sizeof(event)) {
    result[0] = -1;
    result[1] = EIO;
    return result;
  }
  result[0] = 1;
  result[2] = (int64_t)event.time.tv_sec;
  result[3] = (int64_t)event.time.tv_usec;
  result[4] = event.type;
  result[5] = event.code;
  result[6] = event.value;
#else
  result[0] = -1;
  result[1] = 38;
#endif
  return result;
}
