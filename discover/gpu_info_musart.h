#ifndef __APPLE__
#ifndef __GPU_INFO_MUSART_H__
#define __GPU_INFO_MUSART_H__
#include "gpu_info.h"

// Just enough typedef's to dlopen/dlsym for memory information
typedef enum musartReturn_enum {
  MUSART_SUCCESS = 0,
  MUSART_ERROR_INSUFFICIENT_DRIVER = 35,
  // Other values omitted for now...
} musartReturn_t;

typedef enum musartDeviceAttr_enum {
  musartDevAttrComputeCapabilityMajor = 75,
  musartDevAttrComputeCapabilityMinor = 76,
} musartDeviceAttr_t;

typedef struct musartMemory_st {
  size_t total;
  size_t free;
  size_t used;
} musartMemory_t;

typedef struct musartDriverVersion {
  int major;
  int minor;
} musartDriverVersion_t;

typedef struct musaUUID {
    unsigned char bytes[16];
} musaUUID_t;
typedef struct musaDeviceProp {
    char         name[256];                  /**< ASCII string identifying device */
    musaUUID_t   uuid;                       /**< 16-byte unique identifier */
    char         luid[8];                    /**< 8-byte locally unique identifier. Value is undefined on TCC and non-Windows platforms */
    unsigned int luidDeviceNodeMask;         /**< LUID device node mask. Value is undefined on TCC and non-Windows platforms */
    size_t       totalGlobalMem;             /**< Global memory available on device in bytes */
    size_t       sharedMemPerBlock;          /**< Shared memory available per block in bytes */
    int          regsPerBlock;               /**< 32-bit registers available per block */
    int          warpSize;                   /**< Warp size in threads */
    size_t       memPitch;                   /**< Maximum pitch in bytes allowed by memory copies */
    int          maxThreadsPerBlock;         /**< Maximum number of threads per block */
    int          maxThreadsDim[3];           /**< Maximum size of each dimension of a block */
    int          maxGridSize[3];             /**< Maximum size of each dimension of a grid */
    int          clockRate;                  /**< Clock frequency in kilohertz */
    size_t       totalConstMem;              /**< Constant memory available on device in bytes */
    int          major;                      /**< Major compute capability */
    int          minor;                      /**< Minor compute capability */
    size_t       textureAlignment;           /**< Alignment requirement for textures */
    size_t       texturePitchAlignment;      /**< Pitch alignment requirement for texture references bound to pitched memory */
    int          deviceOverlap;              /**< Device can concurrently copy memory and execute a kernel. Deprecated. Use instead asyncEngineCount. */
    int          multiProcessorCount;        /**< Number of multiprocessors on device */
    int          kernelExecTimeoutEnabled;   /**< Specified whether there is a run time limit on kernels */
    int          integrated;                 /**< Device is integrated as opposed to discrete */
    int          canMapHostMemory;           /**< Device can map host memory with musaHostAlloc/musaHostGetDevicePointer */
    int          computeMode;                /**< Compute mode (See ::musaComputeMode) */
    int          maxTexture1D;               /**< Maximum 1D texture size */
    int          maxTexture1DMipmap;         /**< Maximum 1D mipmapped texture size */
    int          maxTexture1DLinear;         /**< Deprecated, do not use. Use musaDeviceGetTexture1DLinearMaxWidth() or muDeviceGetTexture1DLinearMaxWidth() instead. */
    int          maxTexture2D[2];            /**< Maximum 2D texture dimensions */
    int          maxTexture2DMipmap[2];      /**< Maximum 2D mipmapped texture dimensions */
    int          maxTexture2DLinear[3];      /**< Maximum dimensions (width, height, pitch) for 2D textures bound to pitched memory */
    int          maxTexture2DGather[2];      /**< Maximum 2D texture dimensions if texture gather operations have to be performed */
    int          maxTexture3D[3];            /**< Maximum 3D texture dimensions */
    int          maxTexture3DAlt[3];         /**< Maximum alternate 3D texture dimensions */
    int          maxTextureCubemap;          /**< Maximum Cubemap texture dimensions */
    int          maxTexture1DLayered[2];     /**< Maximum 1D layered texture dimensions */
    int          maxTexture2DLayered[3];     /**< Maximum 2D layered texture dimensions */
    int          maxTextureCubemapLayered[2];/**< Maximum Cubemap layered texture dimensions */
    int          maxSurface1D;               /**< Maximum 1D surface size */
    int          maxSurface2D[2];            /**< Maximum 2D surface dimensions */
    int          maxSurface3D[3];            /**< Maximum 3D surface dimensions */
    int          maxSurface1DLayered[2];     /**< Maximum 1D layered surface dimensions */
    int          maxSurface2DLayered[3];     /**< Maximum 2D layered surface dimensions */
    int          maxSurfaceCubemap;          /**< Maximum Cubemap surface dimensions */
    int          maxSurfaceCubemapLayered[2];/**< Maximum Cubemap layered surface dimensions */
    size_t       surfaceAlignment;           /**< Alignment requirements for surfaces */
    int          concurrentKernels;          /**< Device can possibly execute multiple kernels concurrently */
    int          ECCEnabled;                 /**< Device has ECC support enabled */
    int          pciBusID;                   /**< PCI bus ID of the device */
    int          pciDeviceID;                /**< PCI device ID of the device */
    int          pciDomainID;                /**< PCI domain ID of the device */
    int          tccDriver;                  /**< 1 if device is a Tesla device using TCC driver, 0 otherwise */
    int          asyncEngineCount;           /**< Number of asynchronous engines */
    int          unifiedAddressing;          /**< Device shares a unified address space with the host */
    int          memoryClockRate;            /**< Peak memory clock frequency in kilohertz */
    int          memoryBusWidth;             /**< Global memory bus width in bits */
    int          l2CacheSize;                /**< Size of L2 cache in bytes */
    int          persistingL2CacheMaxSize;   /**< Device's maximum l2 persisting lines capacity setting in bytes */
    int          maxThreadsPerMultiProcessor;/**< Maximum resident threads per multiprocessor */
    int          streamPrioritiesSupported;  /**< Device supports stream priorities */
    int          globalL1CacheSupported;     /**< Device supports caching globals in L1 */
    int          localL1CacheSupported;      /**< Device supports caching locals in L1 */
    size_t       sharedMemPerMultiprocessor; /**< Shared memory available per multiprocessor in bytes */
    int          regsPerMultiprocessor;      /**< 32-bit registers available per multiprocessor */
    int          managedMemory;              /**< Device supports allocating managed memory on this system */
    int          isMultiGpuBoard;            /**< Device is on a multi-GPU board */
    int          multiGpuBoardGroupID;       /**< Unique identifier for a group of devices on the same multi-GPU board */
    int          hostNativeAtomicSupported;  /**< Link between the device and the host supports native atomic operations */
    int          singleToDoublePrecisionPerfRatio; /**< Ratio of single precision performance (in floating-point operations per second) to double precision performance */
    int          pageableMemoryAccess;       /**< Device supports coherently accessing pageable memory without calling musaHostRegister on it */
    int          concurrentManagedAccess;    /**< Device can coherently access managed memory concurrently with the CPU */
    int          computePreemptionSupported; /**< Device supports Compute Preemption */
    int          canUseHostPointerForRegisteredMem; /**< Device can access host registered memory at the same virtual address as the CPU */
    int          cooperativeLaunch;          /**< Device supports launching cooperative kernels via ::musaLaunchCooperativeKernel */
    int          cooperativeMultiDeviceLaunch; /**< Deprecated, musaLaunchCooperativeKernelMultiDevice is deprecated. */
    size_t       sharedMemPerBlockOptin;     /**< Per device maximum shared memory per block usable by special opt in */
    int          pageableMemoryAccessUsesHostPageTables; /**< Device accesses pageable memory via the host's page tables */
    int          directManagedMemAccessFromHost; /**< Host can directly access managed memory on the device without migration. */
    int          maxBlocksPerMultiProcessor; /**< Maximum number of resident blocks per multiprocessor */
    int          accessPolicyMaxWindowSize;  /**< The maximum value of ::musaAccessPolicyWindow::num_bytes. */
    size_t       reservedSharedMemPerBlock;  /**< Shared memory reserved by MUSA driver per block in bytes */
} musaDeviceProp_t;

typedef struct musart_handle {
  void *handle;
  uint16_t verbose;
  musartReturn_t (*musaSetDevice)(int device);
  musartReturn_t (*musaDeviceSynchronize)(void);
  musartReturn_t (*musaDeviceReset)(void);
  musartReturn_t (*musaMemGetInfo)(size_t *, size_t *);
  musartReturn_t (*musaGetDeviceCount)(int *);
  musartReturn_t (*musaDeviceGetAttribute)(int* value, musartDeviceAttr_t attr, int device);
  musartReturn_t (*musaDriverGetVersion) (int *driverVersion);
  musartReturn_t (*musaGetDeviceProperties) (musaDeviceProp_t* prop, int device);
} musart_handle_t;

typedef struct musart_init_resp {
  char *err;  // If err is non-null handle is invalid
  musart_handle_t ch;
  int num_devices;
} musart_init_resp_t;

void musart_init(char *musart_lib_path, musart_init_resp_t *resp);
void musart_bootstrap(musart_handle_t ch, int device_id, mem_info_t *resp);
// TODO - if we keep this library longer term, add musart_get_free
void musart_release(musart_handle_t ch);

#endif  // __GPU_INFO_MUSART_H__
#endif  // __APPLE__
