// MTHREADS Management Library (MTML)
//
// https://developer.mthreads.com/sdk/MTML
//
// This library provides accurate VRAM reporting for MTHREADS GPUs.


#include "ggml-impl.h"
#include <mutex>
#include <dlfcn.h>

// Minimal definitions to avoid including the mtml.h header
typedef enum MtmlReturn_enum {
  MTML_SUCCESS = 0,
  MTML_ERROR_NOT_FOUND = 7,
  MTML_ERROR_UNINITIALIZED = 666,
  // Other values omitted for now...
} MtmlReturn;
typedef struct MtmlLibrary MtmlLibrary; // Opaque is sufficient
typedef struct MtmlSystem  MtmlSystem;  // Opaque is sufficient
typedef struct MtmlDevice  MtmlDevice;  // Opaque is sufficient
typedef struct MtmlMemory  MtmlMemory;  // Opaque is sufficient
typedef struct mtmlMemory_st {
  unsigned long long total;
  unsigned long long free;
  unsigned long long used;
} mtmlMemory_t;
// end mtml.h definitions

struct {
  void *handle;
  MtmlLibrary *lib;
  MtmlSystem *sys;
  MtmlReturn (*mtmlLibraryInit)(MtmlLibrary **lib);
  MtmlReturn (*mtmlLibraryInitSystem)(const MtmlLibrary *lib, MtmlSystem **sys);
  MtmlReturn (*mtmlLibraryShutDown)(MtmlLibrary *lib);
  MtmlReturn (*mtmlLibraryInitDeviceByUuid)(const MtmlLibrary *library, const char *uuid, MtmlDevice **dev);
  MtmlReturn (*mtmlDeviceInitMemory)(const MtmlDevice *dev, MtmlMemory **mem);
  MtmlReturn (*mtmlDeviceFreeMemory)(const MtmlMemory *mem);
  MtmlReturn (*mtmlMemoryGetTotal)(const MtmlMemory *mem, unsigned long long *total);
  MtmlReturn (*mtmlMemoryGetUsed)(const MtmlMemory *mem, unsigned long long *used);
} mtml { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
static std::mutex ggml_mtml_lock;

extern "C" {

int ggml_mtml_init() {
    std::lock_guard<std::mutex> lock(ggml_mtml_lock);
    if (mtml.handle != NULL) {
        // Already initialized
        return 0;
    }

    const char *libPath = "/lib/libmtml.so";
    mtml.handle = dlopen(libPath, RTLD_LAZY);
    if (mtml.handle == NULL) {
        return MTML_ERROR_NOT_FOUND;
    }

    struct {
        const char *name;
        void **func;
    } symbols[] = {
        {"mtmlLibraryInit", (void **)&mtml.mtmlLibraryInit},
        {"mtmlLibraryInitSystem", (void **)&mtml.mtmlLibraryInitSystem},
        {"mtmlLibraryShutDown", (void **)&mtml.mtmlLibraryShutDown},
        {"mtmlLibraryInitDeviceByUuid", (void **)&mtml.mtmlLibraryInitDeviceByUuid},
        {"mtmlDeviceInitMemory", (void **)&mtml.mtmlDeviceInitMemory},
        {"mtmlDeviceFreeMemory", (void **)&mtml.mtmlDeviceFreeMemory},
        {"mtmlMemoryGetTotal", (void **)&mtml.mtmlMemoryGetTotal},
        {"mtmlMemoryGetUsed", (void **)&mtml.mtmlMemoryGetUsed},
        {NULL, NULL}
    };

    for (int i = 0; symbols[i].name != NULL; i++) {
        *symbols[i].func = dlsym(mtml.handle, symbols[i].name);
        if (!*symbols[i].func) {
            dlclose(mtml.handle);
            mtml.handle = NULL;
            return MTML_ERROR_NOT_FOUND;
        }
    }

    auto status = mtml.mtmlLibraryInit(&mtml.lib);
    if (status != MTML_SUCCESS) {
        dlclose(mtml.handle);
        mtml.handle = NULL;
        return status;
    }
    status = mtml.mtmlLibraryInitSystem(mtml.lib, &mtml.sys);
    if (status != MTML_SUCCESS) {
        mtml.mtmlLibraryShutDown(mtml.lib);
        dlclose(mtml.handle);
        mtml.handle = NULL;
        return status;
    }
    return MTML_SUCCESS;
}

void ggml_mtml_release() {
    std::lock_guard<std::mutex> lock(ggml_mtml_lock);
    if (mtml.handle == NULL) {
        // Already free
        return;
    }
    MtmlReturn status = mtml.mtmlLibraryShutDown(mtml.lib);
    if (status != MTML_SUCCESS) {
        GGML_LOG_INFO("%s failed to shutdown MTML: %d\n", __func__, status);
    }
    dlclose(mtml.handle);
    mtml.handle = NULL;
}

int ggml_mtml_get_device_memory(const char *uuid, size_t *free, size_t *total) {
    std::lock_guard<std::mutex> lock(ggml_mtml_lock);
    if (mtml.handle == NULL) {
        return MTML_ERROR_UNINITIALIZED;
    }
    MtmlDevice *device;
    auto status = mtml.mtmlLibraryInitDeviceByUuid(mtml.lib, uuid, &device);
    if (status != MTML_SUCCESS) {
        *free = 0;
        *total = 0;
        return status;
    }
    MtmlMemory *memory;
    status = mtml.mtmlDeviceInitMemory(device, &memory);
    if (status != MTML_SUCCESS) {
        *free = 0;
        *total = 0;
        return status;
    }
    mtmlMemory_t memInfo = {0};
    status = mtml.mtmlMemoryGetTotal(memory, &memInfo.total);
    if (status != MTML_SUCCESS) {
        goto exit;
    }
    status = mtml.mtmlMemoryGetUsed(memory, &memInfo.used);
    if (status != MTML_SUCCESS) {
        goto exit;
    }

exit:
    *free = memInfo.free;
    *total = memInfo.total;
    return mtml.mtmlDeviceFreeMemory(memory);
}

}