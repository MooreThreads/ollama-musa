#ifndef __APPLE__
#ifndef __GPU_INFO_VULKAN_H__
#define __GPU_INFO_VULKAN_H__

#include "gpu_info.h"

// DEPRECATED: This define is deprecated. VK_API_VERSION_MAJOR should be used instead.
#define VK_VERSION_MAJOR(version) ((uint32_t)(version) >> 22)

// DEPRECATED: This define is deprecated. VK_API_VERSION_MINOR should be used instead.
#define VK_VERSION_MINOR(version) (((uint32_t)(version) >> 12) & 0x3FFU)

// DEPRECATED: This define is deprecated. VK_API_VERSION_PATCH should be used instead.
#define VK_VERSION_PATCH(version) ((uint32_t)(version) & 0xFFFU)
// Compatibility macros for older Vulkan versions
#ifndef VK_API_VERSION_MAJOR
#define VK_API_VERSION_MAJOR VK_VERSION_MAJOR
#define VK_API_VERSION_MINOR VK_VERSION_MINOR
#define VK_API_VERSION_PATCH VK_VERSION_PATCH
#endif

// DEPRECATED: This define is deprecated. VK_MAKE_API_VERSION should be used instead.
#define VK_MAKE_VERSION(major, minor, patch) \
    ((((uint32_t)(major)) << 22) | (((uint32_t)(minor)) << 12) | ((uint32_t)(patch)))

#define VK_MAKE_API_VERSION(variant, major, minor, patch) \
    ((((uint32_t)(variant)) << 29) | (((uint32_t)(major)) << 22) | (((uint32_t)(minor)) << 12) | ((uint32_t)(patch)))

// DEPRECATED: This define has been removed. Specific version defines (e.g. VK_API_VERSION_1_0), or the VK_MAKE_VERSION macro, should be used instead.
//#define VK_API_VERSION VK_MAKE_VERSION(1, 0, 0) // Patch version should always be set to 0
// Vulkan 1.2 version number
#define VK_API_VERSION_1_2 VK_MAKE_API_VERSION(0, 1, 2, 0)// Patch version should always be set to 0
#define VK_DEFINE_HANDLE(object) typedef struct object##_T* object;
#define VK_MAX_PHYSICAL_DEVICE_NAME_SIZE  256U
#define VK_UUID_SIZE                      16U
#define VK_MAX_EXTENSION_NAME_SIZE        256U
#define VK_MAX_MEMORY_TYPES               32U
#define VK_MAX_MEMORY_HEAPS               16U
#define VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME "VK_KHR_get_physical_device_properties2"

/*
***************************************************************************************************
*   Platform-specific directives and type declarations
***************************************************************************************************
*/

/* Platform-specific calling convention macros.
 *
 * Platforms should define these so that Vulkan clients call Vulkan commands
 * with the same calling conventions that the Vulkan implementation expects.
 *
 * VKAPI_ATTR - Placed before the return type in function declarations.
 *              Useful for C++11 and GCC/Clang-style function attribute syntax.
 * VKAPI_CALL - Placed after the return type in function declarations.
 *              Useful for MSVC-style calling convention syntax.
 * VKAPI_PTR  - Placed between the '(' and '*' in function pointer types.
 *
 * Function declaration:  VKAPI_ATTR void VKAPI_CALL vkCommand(void);
 * Function pointer type: typedef void (VKAPI_PTR *PFN_vkCommand)(void);
 */
#if defined(_WIN32)
    // On Windows, Vulkan commands use the stdcall convention
    #define VKAPI_ATTR
    #define VKAPI_CALL __stdcall
    #define VKAPI_PTR  VKAPI_CALL
#elif defined(__ANDROID__) && defined(__ARM_ARCH) && __ARM_ARCH < 7
    #error "Vulkan is not supported for the 'armeabi' NDK ABI"
#elif defined(__ANDROID__) && defined(__ARM_ARCH) && __ARM_ARCH >= 7 && defined(__ARM_32BIT_STATE)
    // On Android 32-bit ARM targets, Vulkan functions use the "hardfloat"
    // calling convention, i.e. float parameters are passed in registers. This
    // is true even if the rest of the application passes floats on the stack,
    // as it does by default when compiling for the armeabi-v7a NDK ABI.
    #define VKAPI_ATTR __attribute__((pcs("aapcs-vfp")))
    #define VKAPI_CALL
    #define VKAPI_PTR  VKAPI_ATTR
#else
    // On other platforms, use the default calling convention
    #define VKAPI_ATTR
    #define VKAPI_CALL
    #define VKAPI_PTR
#endif

VK_DEFINE_HANDLE(VkInstance)
VK_DEFINE_HANDLE(VkPhysicalDevice)

typedef uint32_t VkBool32;
typedef uint64_t VkDeviceSize;

typedef enum VkMemoryHeapFlagBits {
    VK_MEMORY_HEAP_DEVICE_LOCAL_BIT = 0x00000001,
} VkMemoryHeapFlagBits;


typedef enum VkResult {
    VK_SUCCESS = 0,
} VkResult;

typedef uint32_t VkFlags;
typedef VkFlags VkSampleCountFlags;
typedef struct VkPhysicalDeviceLimits {
    uint32_t              maxImageDimension1D;
    uint32_t              maxImageDimension2D;
    uint32_t              maxImageDimension3D;
    uint32_t              maxImageDimensionCube;
    uint32_t              maxImageArrayLayers;
    uint32_t              maxTexelBufferElements;
    uint32_t              maxUniformBufferRange;
    uint32_t              maxStorageBufferRange;
    uint32_t              maxPushConstantsSize;
    uint32_t              maxMemoryAllocationCount;
    uint32_t              maxSamplerAllocationCount;
    VkDeviceSize          bufferImageGranularity;
    VkDeviceSize          sparseAddressSpaceSize;
    uint32_t              maxBoundDescriptorSets;
    uint32_t              maxPerStageDescriptorSamplers;
    uint32_t              maxPerStageDescriptorUniformBuffers;
    uint32_t              maxPerStageDescriptorStorageBuffers;
    uint32_t              maxPerStageDescriptorSampledImages;
    uint32_t              maxPerStageDescriptorStorageImages;
    uint32_t              maxPerStageDescriptorInputAttachments;
    uint32_t              maxPerStageResources;
    uint32_t              maxDescriptorSetSamplers;
    uint32_t              maxDescriptorSetUniformBuffers;
    uint32_t              maxDescriptorSetUniformBuffersDynamic;
    uint32_t              maxDescriptorSetStorageBuffers;
    uint32_t              maxDescriptorSetStorageBuffersDynamic;
    uint32_t              maxDescriptorSetSampledImages;
    uint32_t              maxDescriptorSetStorageImages;
    uint32_t              maxDescriptorSetInputAttachments;
    uint32_t              maxVertexInputAttributes;
    uint32_t              maxVertexInputBindings;
    uint32_t              maxVertexInputAttributeOffset;
    uint32_t              maxVertexInputBindingStride;
    uint32_t              maxVertexOutputComponents;
    uint32_t              maxTessellationGenerationLevel;
    uint32_t              maxTessellationPatchSize;
    uint32_t              maxTessellationControlPerVertexInputComponents;
    uint32_t              maxTessellationControlPerVertexOutputComponents;
    uint32_t              maxTessellationControlPerPatchOutputComponents;
    uint32_t              maxTessellationControlTotalOutputComponents;
    uint32_t              maxTessellationEvaluationInputComponents;
    uint32_t              maxTessellationEvaluationOutputComponents;
    uint32_t              maxGeometryShaderInvocations;
    uint32_t              maxGeometryInputComponents;
    uint32_t              maxGeometryOutputComponents;
    uint32_t              maxGeometryOutputVertices;
    uint32_t              maxGeometryTotalOutputComponents;
    uint32_t              maxFragmentInputComponents;
    uint32_t              maxFragmentOutputAttachments;
    uint32_t              maxFragmentDualSrcAttachments;
    uint32_t              maxFragmentCombinedOutputResources;
    uint32_t              maxComputeSharedMemorySize;
    uint32_t              maxComputeWorkGroupCount[3];
    uint32_t              maxComputeWorkGroupInvocations;
    uint32_t              maxComputeWorkGroupSize[3];
    uint32_t              subPixelPrecisionBits;
    uint32_t              subTexelPrecisionBits;
    uint32_t              mipmapPrecisionBits;
    uint32_t              maxDrawIndexedIndexValue;
    uint32_t              maxDrawIndirectCount;
    float                 maxSamplerLodBias;
    float                 maxSamplerAnisotropy;
    uint32_t              maxViewports;
    uint32_t              maxViewportDimensions[2];
    float                 viewportBoundsRange[2];
    uint32_t              viewportSubPixelBits;
    size_t                minMemoryMapAlignment;
    VkDeviceSize          minTexelBufferOffsetAlignment;
    VkDeviceSize          minUniformBufferOffsetAlignment;
    VkDeviceSize          minStorageBufferOffsetAlignment;
    int32_t               minTexelOffset;
    uint32_t              maxTexelOffset;
    int32_t               minTexelGatherOffset;
    uint32_t              maxTexelGatherOffset;
    float                 minInterpolationOffset;
    float                 maxInterpolationOffset;
    uint32_t              subPixelInterpolationOffsetBits;
    uint32_t              maxFramebufferWidth;
    uint32_t              maxFramebufferHeight;
    uint32_t              maxFramebufferLayers;
    VkSampleCountFlags    framebufferColorSampleCounts;
    VkSampleCountFlags    framebufferDepthSampleCounts;
    VkSampleCountFlags    framebufferStencilSampleCounts;
    VkSampleCountFlags    framebufferNoAttachmentsSampleCounts;
    uint32_t              maxColorAttachments;
    VkSampleCountFlags    sampledImageColorSampleCounts;
    VkSampleCountFlags    sampledImageIntegerSampleCounts;
    VkSampleCountFlags    sampledImageDepthSampleCounts;
    VkSampleCountFlags    sampledImageStencilSampleCounts;
    VkSampleCountFlags    storageImageSampleCounts;
    uint32_t              maxSampleMaskWords;
    VkBool32              timestampComputeAndGraphics;
    float                 timestampPeriod;
    uint32_t              maxClipDistances;
    uint32_t              maxCullDistances;
    uint32_t              maxCombinedClipAndCullDistances;
    uint32_t              discreteQueuePriorities;
    float                 pointSizeRange[2];
    float                 lineWidthRange[2];
    float                 pointSizeGranularity;
    float                 lineWidthGranularity;
    VkBool32              strictLines;
    VkBool32              standardSampleLocations;
    VkDeviceSize          optimalBufferCopyOffsetAlignment;
    VkDeviceSize          optimalBufferCopyRowPitchAlignment;
    VkDeviceSize          nonCoherentAtomSize;
} VkPhysicalDeviceLimits;

typedef enum VkPhysicalDeviceType {
    // VK_PHYSICAL_DEVICE_TYPE_OTHER = 0,
    // VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU = 1,
    // VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU = 2,
    // VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU = 3,
    VK_PHYSICAL_DEVICE_TYPE_CPU = 4
    // VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM = 0x7FFFFFFF
} VkPhysicalDeviceType;

typedef struct VkPhysicalDeviceSparseProperties {
    VkBool32    residencyStandard2DBlockShape;
    VkBool32    residencyStandard2DMultisampleBlockShape;
    VkBool32    residencyStandard3DBlockShape;
    VkBool32    residencyAlignedMipSize;
    VkBool32    residencyNonResidentStrict;
} VkPhysicalDeviceSparseProperties;
typedef struct VkPhysicalDeviceProperties {
    uint32_t                            apiVersion;
    VkPhysicalDeviceType                deviceType;
    char                                deviceName[VK_MAX_PHYSICAL_DEVICE_NAME_SIZE];
    uint8_t                             pipelineCacheUUID[VK_UUID_SIZE];
} VkPhysicalDeviceProperties;

typedef struct VkExtensionProperties {
    char        extensionName[VK_MAX_EXTENSION_NAME_SIZE];
    uint32_t    specVersion;
} VkExtensionProperties;

typedef enum VkStructureType {
    VK_STRUCTURE_TYPE_APPLICATION_INFO = 0,
    VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2 = 1000059006,
    VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT = 1000237000,
} VkStructureType;

typedef struct VkPhysicalDeviceMemoryBudgetPropertiesEXT {
    VkStructureType    sType;
    void*              pNext;
    VkDeviceSize       heapBudget[VK_MAX_MEMORY_HEAPS];
    VkDeviceSize       heapUsage[VK_MAX_MEMORY_HEAPS];
} VkPhysicalDeviceMemoryBudgetPropertiesEXT;

typedef VkFlags VkInstanceCreateFlags;

typedef struct VkApplicationInfo {
    VkStructureType    sType;
    const void*        pNext;
    const char*        pApplicationName;
    uint32_t           applicationVersion;
    const char*        pEngineName;
    uint32_t           engineVersion;
    uint32_t           apiVersion;
} VkApplicationInfo;
typedef struct VkInstanceCreateInfo {
    VkStructureType             sType;
    const void*                 pNext;
    VkInstanceCreateFlags       flags;
    const VkApplicationInfo*    pApplicationInfo;
    uint32_t                    enabledLayerCount;
    const char* const*          ppEnabledLayerNames;
    uint32_t                    enabledExtensionCount;
    const char* const*          ppEnabledExtensionNames;
} VkInstanceCreateInfo;

typedef enum VkSystemAllocationScope {
    VK_SYSTEM_ALLOCATION_SCOPE_COMMAND = 0,
    VK_SYSTEM_ALLOCATION_SCOPE_OBJECT = 1,
    VK_SYSTEM_ALLOCATION_SCOPE_CACHE = 2,
    VK_SYSTEM_ALLOCATION_SCOPE_DEVICE = 3,
    VK_SYSTEM_ALLOCATION_SCOPE_INSTANCE = 4,
    VK_SYSTEM_ALLOCATION_SCOPE_MAX_ENUM = 0x7FFFFFFF
} VkSystemAllocationScope;

typedef void* (VKAPI_PTR *PFN_vkAllocationFunction)(
    void*                                       pUserData,
    size_t                                      size,
    size_t                                      alignment,
    VkSystemAllocationScope                     allocationScope);



typedef void* (VKAPI_PTR *PFN_vkReallocationFunction)(
    void*                                       pUserData,
    void*                                       pOriginal,
    size_t                                      size,
    size_t                                      alignment,
    VkSystemAllocationScope                     allocationScope);

typedef enum VkInternalAllocationType {
    VK_INTERNAL_ALLOCATION_TYPE_EXECUTABLE = 0,
    VK_INTERNAL_ALLOCATION_TYPE_MAX_ENUM = 0x7FFFFFFF
} VkInternalAllocationType;

typedef void (VKAPI_PTR *PFN_vkFreeFunction)(
    void*                                       pUserData,
    void*                                       pMemory);


    typedef void (VKAPI_PTR *PFN_vkInternalFreeNotification)(
    void*                                       pUserData,
    size_t                                      size,
    VkInternalAllocationType                    allocationType,
    VkSystemAllocationScope                     allocationScope);

typedef void (VKAPI_PTR *PFN_vkInternalAllocationNotification)(
    void*                                       pUserData,
    size_t                                      size,
    VkInternalAllocationType                    allocationType,
    VkSystemAllocationScope                     allocationScope);
    typedef struct VkAllocationCallbacks {
    void*                                   pUserData;
    PFN_vkAllocationFunction                pfnAllocation;
    PFN_vkReallocationFunction              pfnReallocation;
    PFN_vkFreeFunction                      pfnFree;
    PFN_vkInternalAllocationNotification    pfnInternalAllocation;
    PFN_vkInternalFreeNotification          pfnInternalFree;
} VkAllocationCallbacks;

typedef VkFlags VkMemoryPropertyFlags;

typedef struct VkMemoryType {
    VkMemoryPropertyFlags    propertyFlags;
    uint32_t                 heapIndex;
} VkMemoryType;

typedef VkFlags VkMemoryHeapFlags;

typedef struct VkMemoryHeap {
    VkDeviceSize         size;
    VkMemoryHeapFlags    flags;
} VkMemoryHeap;
typedef struct VkPhysicalDeviceMemoryProperties {
    uint32_t        memoryTypeCount;
    VkMemoryType    memoryTypes[VK_MAX_MEMORY_TYPES];
    uint32_t        memoryHeapCount;
    VkMemoryHeap    memoryHeaps[VK_MAX_MEMORY_HEAPS];
} VkPhysicalDeviceMemoryProperties;



typedef struct VkPhysicalDeviceMemoryProperties2 {
    VkStructureType                     sType;
    void*                               pNext;
    VkPhysicalDeviceMemoryProperties    memoryProperties;
} VkPhysicalDeviceMemoryProperties2;

typedef struct {
  void* vk_handle;
  uint16_t verbose;

  VkInstance vk;
  int num_devices;

  void (*vkGetPhysicalDeviceProperties)(
    VkPhysicalDevice                            physicalDevice,
    VkPhysicalDeviceProperties*                 pProperties);
  VkResult (*vkEnumerateDeviceExtensionProperties)(
      VkPhysicalDevice                            physicalDevice,
      const char*                                 pLayerName,
      uint32_t*                                   pPropertyCount,
      VkExtensionProperties*                      pProperties);
  VkResult (*vkCreateInstance)(
      const VkInstanceCreateInfo*                 pCreateInfo,
      const VkAllocationCallbacks*                pAllocator,
      VkInstance*                                 pInstance);
  VkResult (*vkEnumeratePhysicalDevices)(
      VkInstance                                  instance,
      uint32_t*                                   pPhysicalDeviceCount,
      VkPhysicalDevice*                           pPhysicalDevices);
  void (*vkGetPhysicalDeviceMemoryProperties2)(
      VkPhysicalDevice                            physicalDevice,
      VkPhysicalDeviceMemoryProperties2*          pMemoryProperties);
  void (*vkDestroyInstance)(
      VkInstance                                  instance,
      const VkAllocationCallbacks*                pAllocator);
} vk_handle_t;

typedef struct vk_init_resp
{
  char *err; // If err is non-null handle is invalid
  int num_devices;
  vk_handle_t ch;
} vk_init_resp_t;

void vk_init(char* vk_lib_path, vk_init_resp_t *resp);
void vk_check_vram(vk_handle_t rh, int i, mem_info_t *resp);
void vk_release(vk_handle_t rh);

#endif
#endif
