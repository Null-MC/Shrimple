#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(r32f) uniform writeonly image2D imgDepthLod_opaque;

uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

#ifdef VOXY
    uniform sampler2D vxDepthTexTrans;
#endif

uniform float near;
uniform vec2 viewSize;
uniform mat4 vxProjInv;
uniform mat4 dhProjectionInverse;
uniform mat4 gbufferProjectionInverse;


#ifdef DISTANT_HORIZONS
    #define LOD_PROJ_INV dhProjectionInverse
#elif defined(VOXY)
    #define LOD_PROJ_INV vxProjInv
#endif


void main() {
    if (!all(lessThan(gl_GlobalInvocationID.xy, viewSize))) return;

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    float depth = texelFetch(depthtex0, uv, 0).r;

    bool isLod = false;
    if (depth == 1.0) {
        isLod = true;
        #ifdef DISTANT_HORIZONS
            depth = texelFetch(dhDepthTex0, uv, 0).r;
        #elif defined(VOXY)
            depth = texelFetch(vxDepthTexTrans, uv, 0).r;
        #endif
    }

    vec2 texcoord = (uv + 0.5) / viewSize;
    vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = project(isLod ? LOD_PROJ_INV : gbufferProjectionInverse, ndcPos);

    float depthFinal = 0.0;
    if (depth < 1.0) depthFinal = -near / viewPos.z;

    imageStore(imgDepthLod_opaque, uv, vec4(depthFinal));
}
