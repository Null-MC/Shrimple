#define RENDER_COMPOSITE_DIFFUSE_RT_FILTER
#define RENDER_COMPOSITE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

const int sharedBufferRes = 20;
const int sharedBufferSize = _pow2(sharedBufferRes);

shared float gaussianBuffer[5];
shared vec3 sharedDiffuseBuffer[sharedBufferSize];
shared float sharedDepthBuffer[sharedBufferSize];

layout(rgba16f) uniform writeonly image2D imgDiffuseRT;
layout(rgba16f) uniform writeonly image2D imgDiffuseRT_alt;

uniform sampler2D texDiffuseRT;
uniform sampler2D texDiffuseRT_alt;

layout(rgba16f) uniform writeonly image2D imgLocalPosLast;
layout(rgba16f) uniform writeonly image2D imgLocalPosLast_alt;

uniform sampler2D texLocalPosLast;
uniform sampler2D texLocalPosLast_alt;

uniform sampler2D BUFFER_BLOCK_DIFFUSE;
uniform sampler2D BUFFER_VELOCITY;
uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
	uniform sampler2D dhDepthTex0;
#endif

uniform vec2 viewSize;
uniform float near;
uniform float far;
uniform float farPlane;
uniform int frameCounter;

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;

// uniform bool hideGUI;

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/buffers/scene.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/gaussian.glsl"


const float AccumMaxFrames = 30.0;
const float g_sigmaXY = 9.0;
const float g_sigmaV = 0.1;

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
	    vec3 diffuse = vec3(0.0);
	    if (all(greaterThanEqual(uv, ivec2(0))) && all(lessThan(uv, ivec2(viewSize + 0.5)))) {
	    	diffuse = textureLod(BUFFER_BLOCK_DIFFUSE, uv/viewSize, 0).rgb;

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

    	sharedDiffuseBuffer[i_shared] = diffuse;
    	sharedDepthBuffer[i_shared] = depthL;
    }
}

vec3 sampleSharedBuffer(const in float depthL) {
    ivec2 uv_base = ivec2(gl_LocalInvocationID.xy) + 2;

    float total = 0.0;
    vec3 accum = vec3(0.0);
    
    for (int iy = -2; iy <= 2; iy++) {
        float fy = gaussianBuffer[iy+2];

        for (int ix = -2; ix <= 2; ix++) {
            float fx = gaussianBuffer[ix+2];
            
            ivec2 uv_shared = uv_base + ivec2(ix, iy);
            int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;

            vec3 sampleValue = sharedDiffuseBuffer[i_shared];
            float sampleDepthL = sharedDepthBuffer[i_shared];
            
            float fv = Gaussian(g_sigmaV, sampleDepthL - depthL);
            
            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }
    
    if (total <= EPSILON) return vec3(0.0);
    return accum / total;
}


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    populateSharedBuffer();

    // memoryBarrierShared();
    // memoryBarrier();
    barrier();

	if (any(greaterThanEqual(uv, ivec2(viewSize)))) return;

    ivec2 uv_shared = ivec2(gl_LocalInvocationID.xy) + 2;
    int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;
	float depthL = sharedDepthBuffer[i_shared];

    vec2 texcoord = (uv + 0.5) / viewSize;
    bool altFrame = (frameCounter % 2) == 0;

    vec3 velocity = textureLod(BUFFER_VELOCITY, texcoord, 0).xyz;

    #ifdef DISTANT_HORIZONS
        float depth = delinearizeDepth(depthL, near, dhFarPlane);
    #else
        float depth = delinearizeDepth(depthL, near, farPlane);
    #endif

    vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;

    #ifdef DISTANT_HORIZONS
        vec3 viewPos = unproject(dhProjectionFullInv, ndcPos);
    #else
        vec3 viewPos = unproject(gbufferProjectionInverse, ndcPos);
    #endif

    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 localPos_re = localPos + (cameraPosition - previousCameraPosition) - velocity;

    vec3 viewPos_re = mul3(gbufferPreviousModelView, localPos_re);

    #ifdef DISTANT_HORIZONS
        vec3 ndcPos_re = unproject(dhProjectionFullPrev, viewPos_re);
    #else
        vec3 ndcPos_re = unproject(gbufferPreviousProjection, viewPos_re);
    #endif

    vec2 texcoord_re = ndcPos_re.xy * 0.5 + 0.5;


    vec4 diffuseOld = textureLod(altFrame ? texDiffuseRT : texDiffuseRT_alt, texcoord_re, 0);
    float counter = min(diffuseOld.a + 1.0, AccumMaxFrames);

    vec3 localPosLast = textureLod(altFrame ? texLocalPosLast : texLocalPosLast_alt, texcoord_re, 0).rgb;

    float offsetThreshold = clamp(depthL * 0.04, 0.0, 1.0);
    if (distance(localPos_re, localPosLast) > offsetThreshold) counter = 1.0;
    if (saturate(texcoord_re) != texcoord_re) counter = 1.0;

	vec3 diffuseNew = sampleSharedBuffer(depthL);

    diffuseNew = mix(diffuseOld.rgb, diffuseNew, rcp(counter));

    if (altFrame) {
        imageStore(imgDiffuseRT_alt, uv, vec4(diffuseNew, counter));
        imageStore(imgLocalPosLast_alt, uv, vec4(localPos, 0.0));
    }
    else {
        imageStore(imgDiffuseRT, uv, vec4(diffuseNew, counter));
        imageStore(imgLocalPosLast, uv, vec4(localPos, 0.0));
    }
}
