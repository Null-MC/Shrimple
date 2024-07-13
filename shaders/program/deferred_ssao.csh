#define RENDER_DEFERRED_SSAO
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

const int sharedBufferRes = 20;
const int sharedBufferSize = _pow2(sharedBufferRes);

shared float gaussianBuffer[5];
shared float sharedOcclusionBuffer[sharedBufferSize];
shared float sharedDepthBuffer[sharedBufferSize];

layout(r16f) uniform image2D imgSSAO;

uniform sampler2D BUFFER_SSAO;
uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
	uniform sampler2D dhDepthTex0;
#endif

uniform vec2 viewSize;
uniform float near;
uniform float far;
uniform float farPlane;

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/gaussian.glsl"


const float g_sigmaXY = 9.0;
const float g_sigmaV = 0.2;

void populateSharedBuffer() {
    if (gl_LocalInvocationIndex < 5)
        gaussianBuffer[gl_LocalInvocationIndex] = Gaussian(g_sigmaXY, gl_LocalInvocationIndex - 2);
    
    uint i_base = uint(gl_LocalInvocationIndex) * 2u;
    if (i_base >= sharedBufferSize) return;

    ivec2 uv_base = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy) - 2;

    for (uint i = 0u; i < 2u; i++) {
	    uint i_shared = i_base + i;
	    if (i_shared >= sharedBufferSize) break;
	    
    	ivec2 uv_i = ivec2(
            i_shared % sharedBufferRes,
            i_shared / sharedBufferRes
        );

	    ivec2 uv = uv_base + uv_i;

	    float depthL = far;
	    float occlusion = 1.0;
	    if (all(greaterThanEqual(uv, ivec2(0))) && all(lessThan(uv, ivec2(viewSize + 0.5)))) {
	    	occlusion = texelFetch(BUFFER_SSAO, uv, 0).r;
	    	float depth = texelFetch(depthtex0, uv, 0).r;
	    	depthL = linearizeDepth(depth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                float depthDH = texelFetch(dhDepthTex0, uv, 0).r;
                float depthDHL = linearizeDepth(depthDH, dhNearPlane, dhFarPlane);

                if (depth >= 1.0 || (depthDHL < depthL && depthDH > 0.0)) {
                    //depth = depthDH;
                    depthL = depthDHL;
                }
            #endif
	    }

    	sharedOcclusionBuffer[i_shared] = occlusion;
    	sharedDepthBuffer[i_shared] = depthL;
    }
}

float sampleSharedBuffer(const in float depthL) {
	// ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	// return texelFetch(BUFFER_SSAO, uv, 0).r;

    ivec2 uv_base = ivec2(gl_LocalInvocationID.xy) + 2;

    float total = 0.0;
    float accum = 0.0;
    
    for (int iy = -2; iy <= 2; iy++) {
        float fy = gaussianBuffer[iy+2];// Gaussian(g_sigmaXY, iy);

        for (int ix = -2; ix <= 2; ix++) {
            float fx = gaussianBuffer[ix+2];// Gaussian(g_sigmaXY, ix);
            
            ivec2 uv_shared = uv_base + ivec2(ix, iy);
            int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;

            float sampleValue = sharedOcclusionBuffer[i_shared];
            float sampleDepthL = sharedDepthBuffer[i_shared];
            
            float fv = Gaussian(g_sigmaV, abs(sampleDepthL - depthL));
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return 1.0;
    return accum / total;
}


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    populateSharedBuffer();
    barrier();

	if (any(greaterThanEqual(uv, ivec2(viewSize)))) return;

    ivec2 uv_shared = ivec2(gl_LocalInvocationID.xy) + 2;
    int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;
	float depthL = sharedDepthBuffer[i_shared];

	float occlusion = sampleSharedBuffer(depthL);
	imageStore(imgSSAO, uv, vec4(occlusion));
}
