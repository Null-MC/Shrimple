#include "/lib/constants.glsl"
#include "/lib/common.glsl"


layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


shared vec3 sharedBuffer[18*18];

layout(rgba16f) uniform writeonly image2D imgTAA;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_VELOCITY;
uniform usampler2D TEX_META;
uniform sampler2D texTAA_prev;
uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

#ifdef VOXY
    uniform sampler2D vxDepthTexTrans;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 previousCameraPosition;
uniform vec2 viewSize;

uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform mat4 vxProj;
uniform mat4 vxProjInv;

const float TAA_RejectionStrength = 0.1;
const int TAA_MaxAccumFrames = 8;


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 18 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (18*18)) return;

    ivec2 uv_i = ivec2(i_shared % 18, i_shared / 18);
    vec3 color = texelFetch(TEX_FINAL, uv_base + uv_i, 0).rgb;
//    color = color / (1.0 + luminance(color));
    sharedBuffer[i_shared] = color;
}

#ifdef DISTANT_HORIZONS
    #define LOD_PROJ_INV dhProjectionInverse
    #define LOD_PROJ_LAST dhProjection
#elif defined(VOXY)
    #define LOD_PROJ_INV vxProjInv
    #define LOD_PROJ_LAST vxProj
#else
    #define LOD_PROJ_INV gbufferProjectionInverse
    #define LOD_PROJ_LAST gbufferPreviousProjection
#endif

vec3 reproject(const in vec3 ndcPos, const bool isHand, const in bool isLod) {
    if (isHand) return ndcPos;

    vec3 viewPos = project(isLod ? LOD_PROJ_INV : gbufferProjectionInverse, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;

    #if defined(TAA_ENABLED) && defined(WIND_ENABLED)
        ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
        localPosPrev -= texelFetch(TEX_VELOCITY, uv, 0).xyz;
    #endif

    vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);
    return project(isLod ? LOD_PROJ_LAST : gbufferPreviousProjection, viewPosPrev);
}


void main() {
    uint i_base = gl_LocalInvocationIndex * 2u;
    ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 1;

    copyToShared(uv_base, i_base + 0);
    copyToShared(uv_base, i_base + 1);

    memoryBarrierShared();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    if (all(lessThan(uv, viewSize))) {
        float depthNow = texelFetch(depthtex0, uv, 0).r;
        bool isLod = false;

        uint meta = texelFetch(TEX_META, uv, 0).r;
        bool isHand = meta != 0u;
        if (isHand) {
            depthNow = depthNow * 2.0 - 1.0;
            depthNow /= MC_HAND_DEPTH;
            depthNow = depthNow * 0.5 + 0.5;
        }

        #ifdef DISTANT_HORIZONS
            if (depthNow == 1.0) {
                depthNow = texelFetch(dhDepthTex0, uv, 0).r;
                isLod = true;
            }
        #elif defined(VOXY)
            if (depthNow == 1.0) {
                depthNow = texelFetch(vxDepthTexTrans, uv, 0).r;
                isLod = true;
            }
        #endif

        vec2 texcoord = (uv + 0.5) / viewSize;
        vec3 ndcPos = vec3(texcoord, depthNow) * 2.0 - 1.0;
        vec3 ndcPosPrev = reproject(ndcPos, isHand, isLod);
        vec2 texcoord_prev = ndcPosPrev.xy * 0.5 + 0.5;

        #ifdef TAA_SHARPEN_HISTORY
            vec4 lastColor = sample_CatmullRom_RGBA(texTAA_prev, texcoord_prev, viewSize);
        #else
            vec4 lastColor = texture(texTAA_prev, texcoord_prev);
        #endif

        float mixRate = TAA_MaxAccumFrames;//clamp(lastColor.a, 0.0, TAA_MaxAccumFrames);

        if (saturate(texcoord_prev) != texcoord_prev) mixRate = 0.0;

        ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;

        vec3 in0 = sharedBuffer[getSharedIndex(luv)];
        vec3 in1 = sharedBuffer[getSharedIndex(luv + ivec2(+1,  0))];
        vec3 in2 = sharedBuffer[getSharedIndex(luv + ivec2(-1,  0))];
        vec3 in3 = sharedBuffer[getSharedIndex(luv + ivec2( 0, +1))];
        vec3 in4 = sharedBuffer[getSharedIndex(luv + ivec2( 0, -1))];
        vec3 in5 = sharedBuffer[getSharedIndex(luv + ivec2(+1, +1))];
        vec3 in6 = sharedBuffer[getSharedIndex(luv + ivec2(-1, +1))];
        vec3 in7 = sharedBuffer[getSharedIndex(luv + ivec2(+1, -1))];
        vec3 in8 = sharedBuffer[getSharedIndex(luv + ivec2(-1, -1))];

        vec3 antialiased = mix(lastColor.rgb, in0, 1.0 / (mixRate + 1.0));

        vec3 minColor = min(min(min(min(in0, in1), in2), in3), in4);
        minColor = min(min(min(min(minColor, in5), in6), in7), in8);

        vec3 maxColor = max(max(max(max(in0, in1), in2), in3), in4);
        maxColor = max(max(max(max(maxColor, in5), in6), in7), in8);

        vec3 clamped = clamp(antialiased, minColor, maxColor);
//        vec3 diff = clamped - antialiased;
//        mixRate *= 1.0 / (dot(diff, diff) * TAA_RejectionStrength + 1.0);

//        clamped = clamped / (1.0 - luminance(clamped));
        imageStore(imgTAA, uv, vec4(clamped, mixRate + 1.0));
    }
}
