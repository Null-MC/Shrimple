#define RENDER_DEFERRED_HI_Z_RAD_1
#define RENDER_DEFERRED
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 8, local_size_y = 8) in;

const vec2 workGroupsRender = vec2(0.5, 0.5);

layout(r32f) uniform image2D imgDepthNear;

const int sharedSize = 8*2 +2;
shared float sharedBuffer[sharedSize*sharedSize];
// shared float sharedBuffer[324];


uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex;
#endif

uniform vec2 viewSize;
uniform vec2 pixelSize;
uniform float farPlane;
uniform float near;

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/utility/depth_tiles.glsl"
#include "/lib/utility/near_z_radial.glsl"
#include "/lib/sampling/depth.glsl"


void copyToShared(const in ivec2 kernelPos, const in ivec2 depthPos, const in ivec2 sampleOffset) {
    ivec2 sampleUV = clamp(depthPos + sampleOffset, ivec2(0), ivec2(viewSize) - 1);
    float depth = texelFetch(depthtex0, sampleUV, 0).r;

    float depthL = linearizeDepthFast(depth, near, farPlane);

    #ifdef DISTANT_HORIZONS
        float dhDepth = texelFetch(dhDepthTex, sampleUV, 0).r;
        float dhDepthL = linearizeDepthFast(dhDepth, dhNearPlane, dhFarPlane);

        if (depth >= 1.0 || (dhDepth > 0.0 && dhDepthL < depthL)) {
            depth = dhDepth;
            depthL = dhDepthL;
        }

        depthL /= dhFarPlane;
    #else
        depthL /= farPlane;
    #endif

    writeShared(kernelPos + sampleOffset, depthL);
}

void populateSharedBuffer(const in ivec2 kernelPos, const in ivec2 localPos, const in ivec2 globalPos) {
    ivec2 kernelEdgeDir = getKernelDir(localPos);

    ivec2 depthPos = globalPos * 2;
    copyToShared(kernelPos, depthPos, ivec2(0, 0));
    copyToShared(kernelPos, depthPos, ivec2(1, 0));
    copyToShared(kernelPos, depthPos, ivec2(0, 1));
    copyToShared(kernelPos, depthPos, ivec2(1, 1));

    if (localPos.x == 0 || localPos.x == 7) {
        copyToShared(kernelPos, depthPos, ivec2(kernelEdgeDir.x, 0));
        copyToShared(kernelPos, depthPos, ivec2(kernelEdgeDir.x, 1));
    }

    if (localPos.y == 0 || localPos.y == 7) {
        copyToShared(kernelPos, depthPos, ivec2(0, kernelEdgeDir.y));
        copyToShared(kernelPos, depthPos, ivec2(1, kernelEdgeDir.y));
    }
}

void main() {
    ivec2 localPos = ivec2(gl_LocalInvocationID.xy);
    ivec2 globalPos = ivec2(gl_GlobalInvocationID.xy);

    ivec2 kernelPos = localPos * 2 + 1;
    populateSharedBuffer(kernelPos, localPos, globalPos);
    barrier();

    if (any(greaterThanEqual(globalPos, ivec2(ceil(viewSize * 0.5))))) return;

    float minZ = getSharedBufferMinZ(kernelPos);
    writeNearTileMinZ(kernelPos, globalPos, minZ, 0);
}
