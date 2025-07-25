#include "cpy.cuh"
#include "dequantize.cuh"
#if defined(GGML_USE_MUSA) && defined(GGML_MUSA_MUDNN_COPY)
#include "ggml-musa/mudnn.cuh"
#endif // GGML_USE_MUSA && GGML_MUSA_MUDNN_COPY

typedef void (*cpy_kernel_t)(const char * cx, char * cdst);

static __device__ void cpy_1_f32_f32(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    float * dsti = (float *) cdsti;

    *dsti = *xi;
}

static __device__ void cpy_1_f32_bf16(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    nv_bfloat16 * dsti = (nv_bfloat16 *) cdsti;

    *dsti = *xi;
}

static __device__ void cpy_1_f32_f16(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    half * dsti = (half *) cdsti;

    *dsti = __float2half(*xi);
}

static __device__ void cpy_1_f16_f16(const char * cxi, char * cdsti) {
    const half * xi = (const half *) cxi;
    half * dsti = (half *) cdsti;

    *dsti = *xi;
}

static __device__ void cpy_1_f16_f32(const char * cxi, char * cdsti) {
    const half * xi = (const half *) cxi;
    float * dsti = (float *) cdsti;

    *dsti = *xi;
}

static __device__ void cpy_1_i32_i32(const char * cxi, char * cdsti) {
    const int32_t * xi = (const int32_t *) cxi;
    int32_t * dsti = (int32_t *) cdsti;

    *dsti = *xi;
}

template <cpy_kernel_t cpy_1>
static __global__ void cpy_f32_f16(const char * cx, char * cdst_direct, const int ne,
                                   const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
                                   const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11,
                                   const int nb12, const int nb13, char ** cdst_indirect, int graph_cpynode_index) {
    const int64_t i = blockDim.x*blockIdx.x + threadIdx.x;

    if (i >= ne) {
        return;
    }

    char * cdst = (cdst_indirect != nullptr) ? cdst_indirect[graph_cpynode_index]: cdst_direct;

    // determine indices i03/i13, i02/i12, i01/i11, i00/i10 as a function of index i of flattened tensor
    // then combine those indices with the corresponding byte offsets to get the total offsets
    const int64_t i03 = i/(ne00 * ne01 * ne02);
    const int64_t i02 = (i - i03*ne00*ne01*ne02 )/ (ne00*ne01);
    const int64_t i01 = (i - i03*ne00*ne01*ne02  -  i02*ne01*ne00) / ne00;
    const int64_t i00 = i - i03*ne00*ne01*ne02 - i02*ne01*ne00 - i01*ne00;
    const int64_t x_offset = i00*nb00 + i01*nb01 + i02*nb02 + i03 * nb03;

    const int64_t i13 = i/(ne10 * ne11 * ne12);
    const int64_t i12 = (i - i13*ne10*ne11*ne12) / (ne10*ne11);
    const int64_t i11 = (i - i13*ne10*ne11*ne12 - i12*ne10*ne11) / ne10;
    const int64_t i10 = i - i13*ne10*ne11*ne12 - i12*ne10*ne11 - i11*ne10;
    const int64_t dst_offset = i10*nb10 + i11*nb11 + i12*nb12 + i13 * nb13;

    cpy_1(cx + x_offset, cdst + dst_offset);
}

// First, add this template function after the other template functions
template <cpy_kernel_t cpy_1>
static __global__ void cpy_i32_i32(const char * cx, char * cdst, const int ne,
                                 const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
                                 const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11,
                                 const int nb12, const int nb13) {
    const int64_t i = blockDim.x*blockIdx.x + threadIdx.x;

    if (i >= ne) {
        return;
    }

    const int64_t i03 = i/(ne00 * ne01 * ne02);
    const int64_t i02 = (i - i03*ne00*ne01*ne02 )/ (ne00*ne01);
    const int64_t i01 = (i - i03*ne00*ne01*ne02  -  i02*ne01*ne00) / ne00;
    const int64_t i00 = i - i03*ne00*ne01*ne02 - i02*ne01*ne00 - i01*ne00;
    const int64_t x_offset = i00*nb00 + i01*nb01 + i02*nb02 + i03 * nb03;

    const int64_t i13 = i/(ne10 * ne11 * ne12);
    const int64_t i12 = (i - i13*ne10*ne11*ne12) / (ne10*ne11);
    const int64_t i11 = (i - i13*ne10*ne11*ne12 - i12*ne10*ne11) / ne10;
    const int64_t i10 = i - i13*ne10*ne11*ne12 - i12*ne10*ne11 - i11*ne10;
    const int64_t dst_offset = i10*nb10 + i11*nb11 + i12*nb12 + i13 * nb13;

    cpy_1(cx + x_offset, cdst + dst_offset);
}

// Then modify the ggml_cpy_i32_i32_cuda function to use the new template
static void ggml_cpy_i32_i32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_i32_i32<cpy_1_i32_i32><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13);
}

static __device__ void cpy_blck_f32_q8_0(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_q8_0 * dsti = (block_q8_0 *) cdsti;

    float amax = 0.0f; // absolute max

    for (int j = 0; j < QK8_0; j++) {
        const float v = xi[j];
        amax = fmaxf(amax, fabsf(v));
    }

    const float d = amax / ((1 << 7) - 1);
    const float id = d ? 1.0f/d : 0.0f;

    dsti->d = d;

    for (int j = 0; j < QK8_0; ++j) {
        const float x0 = xi[j]*id;

        dsti->qs[j] = roundf(x0);
    }
}

static __device__ void cpy_blck_q8_0_f32(const char * cxi, char * cdsti) {
    float * cdstf = (float *)(cdsti);

#pragma unroll
    for (int j = 0; j < QK8_0; j += 2) {
        dfloat2 dq;
        dequantize_q8_0(cxi, 0, j, dq);
        *(cdstf + j) = dq.x;
        *(cdstf + j + 1) = dq.y;
    }
}

static __device__ void cpy_blck_f32_q4_0(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_q4_0 * dsti = (block_q4_0 *) cdsti;

    float amax = 0.0f;
    float vmax = 0.0f;

    for (int j = 0; j < QK4_0; ++j) {
        const float v = xi[j];
        if (amax < fabsf(v)) {
            amax = fabsf(v);
            vmax = v;
        }
    }

    const float d  = vmax / -8;
    const float id = d ? 1.0f/d : 0.0f;

    dsti->d = d;

    for (int j = 0; j < QK4_0/2; ++j) {
        const float x0 = xi[0       + j]*id;
        const float x1 = xi[QK4_0/2 + j]*id;

        const uint8_t xi0 = min(15, (int8_t)(x0 + 8.5f));
        const uint8_t xi1 = min(15, (int8_t)(x1 + 8.5f));

        dsti->qs[j]  = xi0;
        dsti->qs[j] |= xi1 << 4;
    }
}

static __device__ void cpy_blck_f32_q4_1(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_q4_1 * dsti = (block_q4_1 *) cdsti;

    float vmin = FLT_MAX;
    float vmax = -FLT_MAX;

    for (int j = 0; j < QK4_1; ++j) {
        const float v = xi[j];

        if (v < vmin) vmin = v;
        if (v > vmax) vmax = v;
    }

    const float d  = (vmax - vmin) / ((1 << 4) - 1);
    const float id = d ? 1.0f/d : 0.0f;

    dsti->dm.x = d;
    dsti->dm.y = vmin;

    for (int j = 0; j < QK4_1/2; ++j) {
        const float x0 = (xi[0       + j] - vmin)*id;
        const float x1 = (xi[QK4_1/2 + j] - vmin)*id;

        const uint8_t xi0 = min(15, (int8_t)(x0 + 0.5f));
        const uint8_t xi1 = min(15, (int8_t)(x1 + 0.5f));

        dsti->qs[j]  = xi0;
        dsti->qs[j] |= xi1 << 4;
    }
}

static __device__ void cpy_blck_f32_q5_0(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_q5_0 * dsti = (block_q5_0 *) cdsti;

    float amax = 0.0f;
    float vmax = 0.0f;

    for (int j = 0; j < QK5_0; ++j) {
        const float v = xi[j];
        if (amax < fabsf(v)) {
            amax = fabsf(v);
            vmax = v;
        }
    }

    const float d  = vmax / -16;
    const float id = d ? 1.0f/d : 0.0f;

    dsti->d = d;

    uint32_t qh = 0;
    for (int j = 0; j < QK5_0/2; ++j) {
        const float x0 = xi[0       + j]*id;
        const float x1 = xi[QK5_0/2 + j]*id;

        const uint8_t xi0 = min(31, (int8_t)(x0 + 16.5f));
        const uint8_t xi1 = min(31, (int8_t)(x1 + 16.5f));

        dsti->qs[j]  = (xi0 & 0xf) | ((xi1 & 0xf) << 4);
        qh |= ((xi0 & 0x10u) >> 4) << (j + 0);
        qh |= ((xi1 & 0x10u) >> 4) << (j + QK5_0/2);
    }
    memcpy(dsti->qh, &qh, sizeof(qh));
}

static __device__ void cpy_blck_f32_q5_1(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_q5_1 * dsti = (block_q5_1 *) cdsti;

    float min = xi[0];
    float max = xi[0];

    for (int j = 1; j < QK5_1; ++j) {
        const float v = xi[j];
        min = v < min ? v : min;
        max = v > max ? v : max;
    }

    const float d  = (max - min) / 31;
    const float id = d ? 1.0f/d : 0.0f;

    dsti->dm.x = d;
    dsti->dm.y = min;

    uint32_t qh = 0;
    for (int j = 0; j < QK5_1/2; ++j) {
        const float x0 = (xi[0       + j] - min)*id;
        const float x1 = (xi[QK5_1/2 + j] - min)*id;

        const uint8_t xi0 = (uint8_t)(x0 + 0.5f);
        const uint8_t xi1 = (uint8_t)(x1 + 0.5f);

        dsti->qs[j]  = (xi0 & 0xf) | ((xi1 & 0xf) << 4);
        qh |= ((xi0 & 0x10u) >> 4) << (j + 0);
        qh |= ((xi1 & 0x10u) >> 4) << (j + QK5_1/2);
    }
    memcpy(dsti->qh, &qh, sizeof(qh));
}

template<dequantize_kernel_t dequant, int qk>
static __device__ void cpy_blck_q_f32(const char * cxi, char * cdsti) {
    float * cdstf = (float *)(cdsti);

#pragma unroll
    for (int j = 0; j < qk/2; j++) {
        dfloat2 dq;
        dequant(cxi, 0, j, dq);
        *(cdstf + j) = dq.x;
        *(cdstf + j + qk/2) = dq.y;
    }
}

static __device__ __forceinline__ int best_index_int8(int n, const int8_t * val, float x) {
    if (x <= val[0]) return 0;
    if (x >= val[n-1]) return n-1;
    int ml = 0, mu = n-1;
    while (mu-ml > 1) {
        int mav = (ml+mu)/2;
        if (x < val[mav]) mu = mav; else ml = mav;
    }
    return x - val[mu-1] < val[mu] - x ? mu-1 : mu;
}

static __device__ void cpy_blck_f32_iq4_nl(const char * cxi, char * cdsti) {
    const float * xi = (const float *) cxi;
    block_iq4_nl * dsti = (block_iq4_nl *) cdsti;

    float amax = 0.0f;
    float vmax = 0.0f;

    for (int j = 0; j < QK4_NL; ++j) {
        const float v = xi[j];
        if (amax < fabsf(v)) {
            amax = fabsf(v);
            vmax = v;
        }
    }

    float d = vmax / kvalues_iq4nl[0];
    const float id = d ? 1.0f/d : 0.0f;

    float sumqx = 0, sumq2 = 0;
    for (int j = 0; j < QK4_NL/2; ++j) {
        const float x0 = xi[0        + j]*id;
        const float x1 = xi[QK4_NL/2 + j]*id;
        const uint8_t xi0 = best_index_int8(16, kvalues_iq4nl, x0);
        const uint8_t xi1 = best_index_int8(16, kvalues_iq4nl, x1);
        dsti->qs[j] = xi0 | (xi1 << 4);
        const float v0 = kvalues_iq4nl[xi0];
        const float v1 = kvalues_iq4nl[xi1];
        const float w0 = xi[0        + j]*xi[0        + j];
        const float w1 = xi[QK4_NL/2 + j]*xi[QK4_NL/2 + j];
        sumqx += w0*v0*xi[j] + w1*v1*xi[QK4_NL/2 + j];
        sumq2 += w0*v0*v0 + w1*v1*v1;
    }

    dsti->d = sumq2 > 0 ? sumqx/sumq2 : d;
}

template <cpy_kernel_t cpy_blck, int qk>
static __global__ void cpy_f32_q(const char * cx, char * cdst_direct, const int ne,
                                 const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
                                 const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11,
                                 const int nb12, const int nb13, char ** cdst_indirect, int graph_cpynode_index) {
    const int i = (blockDim.x*blockIdx.x + threadIdx.x)*qk;

    if (i >= ne) {
        return;
    }

    char * cdst = (cdst_indirect != nullptr) ? cdst_indirect[graph_cpynode_index]: cdst_direct;

    const int i03 = i/(ne00 * ne01 * ne02);
    const int i02 = (i - i03*ne00*ne01*ne02 )/ (ne00*ne01);
    const int i01 = (i - i03*ne00*ne01*ne02  -  i02*ne01*ne00) / ne00;
    const int i00 = i - i03*ne00*ne01*ne02 - i02*ne01*ne00 - i01*ne00;
    const int x_offset = i00*nb00 + i01*nb01 + i02*nb02 + i03 * nb03;

    const int i13 = i/(ne10 * ne11 * ne12);
    const int i12 = (i - i13*ne10*ne11*ne12) / (ne10*ne11);
    const int i11 = (i - i13*ne10*ne11*ne12 - i12*ne10*ne11) / ne10;
    const int i10 = i - i13*ne10*ne11*ne12 - i12*ne10*ne11 - i11*ne10;
    const int dst_offset = (i10/qk)*nb10 + i11*nb11 + i12*nb12 + i13*nb13;

    cpy_blck(cx + x_offset, cdst + dst_offset);
}

template <cpy_kernel_t cpy_blck, int qk>
static __global__ void cpy_q_f32(const char * cx, char * cdst_direct, const int ne,
                                 const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
                                 const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11,
                                 const int nb12, const int nb13, char ** cdst_indirect, int graph_cpynode_index) {
    const int i = (blockDim.x*blockIdx.x + threadIdx.x)*qk;

    if (i >= ne) {
        return;
    }

    char * cdst = (cdst_indirect != nullptr) ? cdst_indirect[graph_cpynode_index]: cdst_direct;

    const int i03 = i/(ne00 * ne01 * ne02);
    const int i02 = (i - i03*ne00*ne01*ne02 )/ (ne00*ne01);
    const int i01 = (i - i03*ne00*ne01*ne02  -  i02*ne01*ne00) / ne00;
    const int i00 = i - i03*ne00*ne01*ne02 - i02*ne01*ne00 - i01*ne00;
    const int x_offset = (i00/qk)*nb00 + i01*nb01 + i02*nb02 + i03 * nb03;

    const int i13 = i/(ne10 * ne11 * ne12);
    const int i12 = (i - i13*ne10*ne11*ne12) / (ne10*ne11);
    const int i11 = (i - i13*ne10*ne11*ne12 - i12*ne10*ne11) / ne10;
    const int i10 = i - i13*ne10*ne11*ne12 - i12*ne10*ne11 - i11*ne10;
    const int dst_offset = i10*nb10 + i11*nb11 + i12*nb12 + i13*nb13;

    cpy_blck(cx + x_offset, cdst + dst_offset);
}

// Copy destination pointers to GPU to be available when pointer indirection is in use

void ggml_cuda_cpy_dest_ptrs_copy(ggml_cuda_graph * cuda_graph, char ** host_dest_ptrs, const int host_dest_ptrs_size, cudaStream_t stream) {
#if defined(GGML_CUDA_USE_GRAPHS) || defined(GGML_HIP_GRAPHS)
    if (cuda_graph->dest_ptrs_size < host_dest_ptrs_size) { // (re-)allocate GPU memory for destination pointers
        CUDA_CHECK(cudaStreamSynchronize(stream));
        if (cuda_graph->dest_ptrs_d != nullptr) {
            CUDA_CHECK(cudaFree(cuda_graph->dest_ptrs_d));
        }
        CUDA_CHECK(cudaMalloc(&cuda_graph->dest_ptrs_d, host_dest_ptrs_size*sizeof(char *)));
        cuda_graph->dest_ptrs_size = host_dest_ptrs_size;
    }
    // copy destination pointers to GPU
    CUDA_CHECK(cudaMemcpyAsync(cuda_graph->dest_ptrs_d, host_dest_ptrs, host_dest_ptrs_size*sizeof(char *), cudaMemcpyHostToDevice, stream));
    cuda_graph->graph_cpynode_index = 0; // reset index
#else
    GGML_UNUSED(cuda_graph); GGML_UNUSED(host_dest_ptrs);
    GGML_UNUSED(host_dest_ptrs_size); GGML_UNUSED(stream);
#endif
}

static void ggml_cpy_f16_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_f32_f16<cpy_1_f16_f32><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_f32_f16<cpy_1_f32_f32><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_bf16_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_f32_f16<cpy_1_f32_bf16><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_f16_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_f32_f16<cpy_1_f32_f16><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_q8_0_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK8_0 == 0);
    const int num_blocks = ne / QK8_0;
    cpy_f32_q<cpy_blck_f32_q8_0, QK8_0><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_q8_0_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = ne;
    cpy_q_f32<cpy_blck_q8_0_f32, QK8_0><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_q4_0_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK4_0 == 0);
    const int num_blocks = ne / QK4_0;
    cpy_f32_q<cpy_blck_f32_q4_0, QK4_0><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_q4_0_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02,
    const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12,
    const int nb10, const int nb11, const int nb12, const int nb13,
    cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {
    const int num_blocks = ne;
    cpy_q_f32<cpy_blck_q_f32<dequantize_q4_0, QK4_0>, QK4_0><<<num_blocks, 1, 0, stream>>>(
        cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03,
         ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_q4_1_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK4_1 == 0);
    const int num_blocks = ne / QK4_1;
    cpy_f32_q<cpy_blck_f32_q4_1, QK4_1><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_q4_1_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02,
    const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12,
    const int nb10, const int nb11, const int nb12, const int nb13,
    cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {
    const int num_blocks = ne;
    cpy_q_f32<cpy_blck_q_f32<dequantize_q4_1, QK4_1>, QK4_1><<<num_blocks, 1, 0, stream>>>(
        cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03,
         ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_q5_0_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK5_0 == 0);
    const int num_blocks = ne / QK5_0;
    cpy_f32_q<cpy_blck_f32_q5_0, QK5_0><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_q5_0_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02,
    const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12,
    const int nb10, const int nb11, const int nb12, const int nb13,
    cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {
    const int num_blocks = ne;
    cpy_q_f32<cpy_blck_q_f32<dequantize_q5_0, QK5_0>, QK5_0><<<num_blocks, 1, 0, stream>>>(
        cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03,
        ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_q5_1_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK5_1 == 0);
    const int num_blocks = ne / QK5_1;
    cpy_f32_q<cpy_blck_f32_q5_1, QK5_1><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_q5_1_f32_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02,
    const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12,
    const int nb10, const int nb11, const int nb12, const int nb13,
    cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {
    const int num_blocks = ne;
    cpy_q_f32<cpy_blck_q_f32<dequantize_q5_1, QK5_1>, QK5_1><<<num_blocks, 1, 0, stream>>>(
        cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03,
        ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f32_iq4_nl_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    GGML_ASSERT(ne % QK4_NL == 0);
    const int num_blocks = ne / QK4_NL;
    cpy_f32_q<cpy_blck_f32_iq4_nl, QK4_NL><<<num_blocks, 1, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

static void ggml_cpy_f16_f16_cuda(
    const char * cx, char * cdst, const int ne,
    const int ne00, const int ne01, const int ne02, const int nb00, const int nb01, const int nb02,
    const int nb03, const int ne10, const int ne11, const int ne12, const int nb10, const int nb11, const int nb12, const int nb13, cudaStream_t stream, char ** cdst_indirect, int & graph_cpynode_index) {

    const int num_blocks = (ne + CUDA_CPY_BLOCK_SIZE - 1) / CUDA_CPY_BLOCK_SIZE;
    cpy_f32_f16<cpy_1_f16_f16><<<num_blocks, CUDA_CPY_BLOCK_SIZE, 0, stream>>>
        (cx, cdst, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, cdst_indirect, graph_cpynode_index++);
}

void ggml_cuda_cpy(ggml_backend_cuda_context & ctx, const ggml_tensor * src0, ggml_tensor * src1, bool disable_indirection_for_this_node) {
    const int64_t ne = ggml_nelements(src0);
    GGML_ASSERT(ne == ggml_nelements(src1));

    GGML_ASSERT(ggml_nbytes(src0) <= INT_MAX);
    GGML_ASSERT(ggml_nbytes(src1) <= INT_MAX);

    const int64_t ne00 = src0->ne[0];
    const int64_t ne01 = src0->ne[1];
    const int64_t ne02 = src0->ne[2];

    //GGML_ASSERT(src0->ne[3] == 1);

    const int64_t nb00 = src0->nb[0];
    const int64_t nb01 = src0->nb[1];
    const int64_t nb02 = src0->nb[2];
    const int64_t nb03 = src0->nb[3];

    const int64_t ne10 = src1->ne[0];
    const int64_t ne11 = src1->ne[1];
    const int64_t ne12 = src1->ne[2];

    //GGML_ASSERT(src1->ne[3] == 1);

    const int64_t nb10 = src1->nb[0];
    const int64_t nb11 = src1->nb[1];
    const int64_t nb12 = src1->nb[2];
    const int64_t nb13 = src1->nb[3];

    cudaStream_t main_stream = ctx.stream();

    char * src0_ddc = (char *) src0->data;
    char * src1_ddc = (char *) src1->data;

    char ** dest_ptrs_d = nullptr;
    int graph_cpynode_index = -1;
#if defined(GGML_CUDA_USE_GRAPHS) || defined(GGML_HIP_GRAPHS)
    if(ctx.cuda_graph->use_cpy_indirection && !disable_indirection_for_this_node) {
        dest_ptrs_d = ctx.cuda_graph->dest_ptrs_d;
        graph_cpynode_index = ctx.cuda_graph->graph_cpynode_index;
    }
#else
    GGML_UNUSED(disable_indirection_for_this_node);
#endif
    if (src0->type == src1->type && ggml_is_contiguous(src0) && ggml_is_contiguous(src1)) {
        GGML_ASSERT(ggml_nbytes(src0) == ggml_nbytes(src1));
#if defined(GGML_USE_MUSA) && defined(GGML_MUSA_MUDNN_COPY)
        if (src0->type == GGML_TYPE_F32 || src0->type == GGML_TYPE_F16) {
            CUDA_CHECK(mudnnMemcpyAsync(ctx, src1, src0));
        } else
#endif // GGML_USE_MUSA && GGML_MUSA_MUDNN_COPY
        {
            CUDA_CHECK(cudaMemcpyAsync(src1_ddc, src0_ddc, ggml_nbytes(src0), cudaMemcpyDeviceToDevice, main_stream));
        }
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_f32_f32_cuda (src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_BF16) {
        ggml_cpy_f32_bf16_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_F16) {
        ggml_cpy_f32_f16_cuda (src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q8_0) {
        ggml_cpy_f32_q8_0_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_Q8_0 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_q8_0_f32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q4_0) {
        ggml_cpy_f32_q4_0_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_Q4_0 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_q4_0_f32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02,
            nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q4_1) {
        ggml_cpy_f32_q4_1_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_Q4_1 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_q4_1_f32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02,
            nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q5_0) {
        ggml_cpy_f32_q5_0_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_Q5_0 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_q5_0_f32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02,
            nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_IQ4_NL) {
        ggml_cpy_f32_iq4_nl_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q5_1) {
        ggml_cpy_f32_q5_1_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_Q5_1 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_q5_1_f32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F16 && src1->type == GGML_TYPE_F16) {
        ggml_cpy_f16_f16_cuda (src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_F16 && src1->type == GGML_TYPE_F32) {
        ggml_cpy_f16_f32_cuda (src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else if (src0->type == GGML_TYPE_I32 && src1->type == GGML_TYPE_I32) {
        ggml_cpy_i32_i32_cuda(src0_ddc, src1_ddc, ne, ne00, ne01, ne02, nb00, nb01, nb02, nb03, ne10, ne11, ne12, nb10, nb11, nb12, nb13, main_stream, dest_ptrs_d, graph_cpynode_index);
    } else {
        GGML_ABORT("%s: unsupported type combination (%s to %s)\n", __func__,
                ggml_type_name(src0->type), ggml_type_name(src1->type));
    }
#if defined(GGML_CUDA_USE_GRAPHS) || defined(GGML_HIP_GRAPHS)
    if(ctx.cuda_graph->use_cpy_indirection && !disable_indirection_for_this_node) {
        ctx.cuda_graph->graph_cpynode_index = graph_cpynode_index;
    }
#else
    GGML_UNUSED(disable_indirection_for_this_node);
#endif

}

void ggml_cuda_dup(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    const ggml_tensor * src0 = dst->src[0];
    bool disable_indirection = true;
    ggml_cuda_cpy(ctx, src0, dst, disable_indirection);
}

void* ggml_cuda_cpy_fn(const ggml_tensor * src0, ggml_tensor * src1) {
    if (src0->type == src1->type && ggml_is_contiguous(src0) && ggml_is_contiguous(src1)) {
        return nullptr;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_f32_f16<cpy_1_f32_f32>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_BF16) {
        return (void*) cpy_f32_f16<cpy_1_f32_bf16>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_F16) {
        return (void*) cpy_f32_f16<cpy_1_f32_f16>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q8_0) {
        return (void*) cpy_f32_q<cpy_blck_f32_q8_0, QK8_0>;
    } else if (src0->type == GGML_TYPE_Q8_0 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_q_f32<cpy_blck_q8_0_f32, QK8_0>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q4_0) {
        return (void*) cpy_f32_q<cpy_blck_f32_q4_0, QK4_0>;
    } else if (src0->type == GGML_TYPE_Q4_0 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_q_f32<cpy_blck_q_f32<dequantize_q4_0, QK4_0>, QK4_0>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q4_1) {
        return (void*) cpy_f32_q<cpy_blck_f32_q4_1, QK4_1>;
    } else if (src0->type == GGML_TYPE_Q4_1 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_q_f32<cpy_blck_q_f32<dequantize_q4_1, QK4_1>, QK4_1>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q5_0) {
        return (void*) cpy_f32_q<cpy_blck_f32_q5_0, QK5_0>;
    } else if (src0->type == GGML_TYPE_Q5_0 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_q_f32<cpy_blck_q_f32<dequantize_q5_0, QK5_0>, QK5_0>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_IQ4_NL) {
        return (void*) cpy_f32_q<cpy_blck_f32_iq4_nl, QK4_NL>;
    } else if (src0->type == GGML_TYPE_F32 && src1->type == GGML_TYPE_Q5_1) {
        return (void*) cpy_f32_q<cpy_blck_f32_q5_1, QK5_1>;
    } else if (src0->type == GGML_TYPE_Q5_1 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_q_f32<cpy_blck_q_f32<dequantize_q5_1, QK5_1>, QK5_1>;
    } else if (src0->type == GGML_TYPE_F16 && src1->type == GGML_TYPE_F16) {
        return (void*) cpy_f32_f16<cpy_1_f32_f16>;
    } else if (src0->type == GGML_TYPE_F16 && src1->type == GGML_TYPE_F32) {
        return (void*) cpy_f32_f16<cpy_1_f16_f32>;
    } else if (src0->type == GGML_TYPE_I32 && src1->type == GGML_TYPE_I32) {
        return (void*) cpy_i32_i32<cpy_1_i32_i32>;
    } else {
        GGML_ABORT("%s: unsupported type combination (%s to %s)\n", __func__,
                ggml_type_name(src0->type), ggml_type_name(src1->type));
    }
}
