#include "moonbit.h"

#include <errno.h>
#include <stdint.h>
#include <string.h>

#ifdef __linux__
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <sys/ioctl.h>
#include <unistd.h>
#endif

typedef struct { int fd; int error; int created; } mooninput_uinput_device;

static void mooninput_uinput_finalize(void *self) {
  mooninput_uinput_device *device = (mooninput_uinput_device *)self;
#ifdef __linux__
  if (device->fd >= 0) {
    if (device->created) ioctl(device->fd, UI_DEV_DESTROY);
    close(device->fd);
    device->fd = -1;
  }
#else
  (void)device;
#endif
}

MOONBIT_FFI_EXPORT mooninput_uinput_device *mooninput_uinput_open(void) {
  mooninput_uinput_device *device = moonbit_make_external_object(mooninput_uinput_finalize, sizeof(*device));
  device->fd = -1; device->error = 0; device->created = 0;
#ifdef __linux__
  device->fd = open("/dev/uinput", O_WRONLY | O_CLOEXEC);
  if (device->fd < 0) device->error = errno;
#else
  device->error = 38;
#endif
  return device;
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_error(mooninput_uinput_device *d) { return d->error; }
MOONBIT_FFI_EXPORT int32_t mooninput_uinput_is_open(mooninput_uinput_device *d) { return d->fd >= 0; }

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_sysname(mooninput_uinput_device *d, uint8_t *buffer) {
#ifdef __linux__
  if (d->fd < 0) return -EBADF;
  uint32_t capacity = Moonbit_array_length(buffer);
  if (capacity < 2) return -EINVAL;
  memset(buffer, 0, capacity);
  if (ioctl(d->fd, UI_GET_SYSNAME(capacity), buffer) < 0) return -errno;
  return (int32_t)strnlen((const char *)buffer, capacity);
#else
  (void)d; (void)buffer; return -38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_setup(mooninput_uinput_device *d, moonbit_bytes_t name, int32_t bus, int32_t vendor, int32_t product, int32_t version) {
#ifdef __linux__
  struct uinput_setup setup; uint32_t n = Moonbit_array_length(name);
  if (d->fd < 0) return EBADF;
  if (n == 0 || n >= UINPUT_MAX_NAME_SIZE || memchr(name, '\0', n) != NULL) return EINVAL;
  memset(&setup, 0, sizeof(setup)); memcpy(setup.name, name, n);
  setup.id.bustype = (uint16_t)bus; setup.id.vendor = (uint16_t)vendor; setup.id.product = (uint16_t)product; setup.id.version = (uint16_t)version;
  if (ioctl(d->fd, UI_SET_EVBIT, EV_SYN) < 0) return errno;
  if (ioctl(d->fd, UI_DEV_SETUP, &setup) < 0) return errno;
  return 0;
#else
  (void)d; (void)name; (void)bus; (void)vendor; (void)product; (void)version; return 38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_set_capability(mooninput_uinput_device *d, int32_t event_type, int32_t code) {
#ifdef __linux__
  if (d->fd < 0) return EBADF;
  if (ioctl(d->fd, UI_SET_EVBIT, event_type) < 0) return errno;
  unsigned long request = event_type == EV_KEY ? UI_SET_KEYBIT : event_type == EV_REL ? UI_SET_RELBIT : UI_SET_ABSBIT;
  if (ioctl(d->fd, request, code) < 0) return errno;
  return 0;
#else
  (void)d; (void)event_type; (void)code; return 38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_set_absolute(mooninput_uinput_device *d, int32_t code, int32_t minimum, int32_t maximum, int32_t fuzz, int32_t flat, int32_t resolution) {
#ifdef __linux__
  if (d->fd < 0) return EBADF;
  struct uinput_abs_setup setup; memset(&setup, 0, sizeof(setup));
  setup.code = (uint16_t)code; setup.absinfo.minimum = minimum; setup.absinfo.maximum = maximum;
  setup.absinfo.fuzz = fuzz; setup.absinfo.flat = flat; setup.absinfo.resolution = resolution;
  if (ioctl(d->fd, UI_ABS_SETUP, &setup) < 0) return errno;
  return 0;
#else
  (void)d; (void)code; (void)minimum; (void)maximum; (void)fuzz; (void)flat; (void)resolution; return 38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_create(mooninput_uinput_device *d) {
#ifdef __linux__
  if (d->fd < 0) return EBADF;
  if (ioctl(d->fd, UI_DEV_CREATE) < 0) return errno;
  d->created = 1; return 0;
#else
  (void)d; return 38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_emit(mooninput_uinput_device *d, int32_t event_type, int32_t code, int32_t value) {
#ifdef __linux__
  if (d->fd < 0) return EBADF;
  if (!d->created) return ENODEV;
  struct input_event event; memset(&event, 0, sizeof(event));
  event.type = (uint16_t)event_type; event.code = (uint16_t)code; event.value = value;
  ssize_t written;
  do { written = write(d->fd, &event, sizeof(event)); } while (written < 0 && errno == EINTR);
  if (written < 0) return errno;
  return written == (ssize_t)sizeof(event) ? 0 : EIO;
#else
  (void)d; (void)event_type; (void)code; (void)value; return 38;
#endif
}

MOONBIT_FFI_EXPORT int32_t mooninput_uinput_close(mooninput_uinput_device *d) {
#ifdef __linux__
  if (d->fd < 0) return 0;
  int fd = d->fd; d->fd = -1;
  if (d->created) { if (ioctl(fd, UI_DEV_DESTROY) < 0) { int e = errno; close(fd); d->created = 0; return e; } d->created = 0; }
  if (close(fd) < 0) return errno;
#else
  (void)d;
#endif
  return 0;
}
