#include "moonbit.h"

#ifdef __linux__
#include <time.h>
#endif

MOONBIT_FFI_EXPORT void mooninput_roundtrip_wait(void) {
#ifdef __linux__
  struct timespec pause = { .tv_sec = 0, .tv_nsec = 10000000 };
  nanosleep(&pause, NULL);
#endif
}
