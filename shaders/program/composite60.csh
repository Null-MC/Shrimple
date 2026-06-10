#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef LOD_ENABLED
    #define TEX_DEPTH texDepthLod_trans
    #define MAT_PROJ_INV matProjInv
    #define MAT_PROJ_LAST matProjLast
#else
    #define TEX_DEPTH depthtex0
    #define MAT_PROJ_INV gbufferProjectionInverse
    #define MAT_PROJ_LAST gbufferPreviousProjection
#endif


layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);

#if RENDER_SCALE == 0
    shared vec3 sharedBuffer[18*18];
#endif

layout(rgba16f) uniform writeonly image2D imgTAA;

uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_VELOCITY;
uniform usampler2D TEX_GB_SPECULAR;
uniform sampler2D texTAA_prev;

uniform float near;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 previousCameraPosition;
uniform vec2 viewSize;

#ifdef LOD_ENABLED
    #include "/lib/lod-projection.glsl"
#endif


const float TAA_RejectionStrength = 0.1;
const int TAA_MaxAccumFrames = 8;

#if RENDER_SCALE == 0
    int getSharedIndex(const in ivec2 uv) {
        return uv.y * 18 + uv.x;
    }

    void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
        if (i_shared >= (18*18)) return;

        ivec2 uv = ivec2(i_shared % 18, i_shared / 18) + uv_base;

    //    #if RENDER_SCALE != 0
    //        uv = ivec2(uv * RENDER_SCALE_F);
    //    #endif

    //    sharedBuffer[i_shared] = TexelFetchLinearRGB(TEX_FINAL, uv + 0.5, 0).rgb;
        sharedBuffer[i_shared] = texelFetch(TEX_FINAL, uv, 0).rgb;
    }
#endif

vec3 reproject(const in vec3 ndcPos, const bool isHand) {
    if (isHand) return ndcPos;

    #ifdef LOD_ENABLED
        mat4 matProjInv = GetLodProjectionInverse(gbufferProjectionInverse, near);
        mat4 matProjLast = GetLodProjection(gbufferPreviousProjection, near);
    #endif

    vec3 viewPos = project(MAT_PROJ_INV, ndcPos);
    vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

    vec3 localPosPrev = localPos + cameraPosition - previousCameraPosition;

    #ifdef VELOCITY_ENABLED
        ivec2 uv_in = ivec2(gl_GlobalInvocationID.xy * RENDER_SCALE_F);
        localPosPrev -= texelFetch(TEX_VELOCITY, uv_in, 0).xyz;

//        vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / viewSize;
//        localPosPrev -= texture(TEX_VELOCITY, texcoord).xyz;
    #endif

    vec3 viewPosPrev = mul3(gbufferPreviousModelView, localPosPrev);
    return project(MAT_PROJ_LAST, viewPosPrev);
}


void main() {
    #if RENDER_SCALE == 0
        uint i_base = gl_LocalInvocationIndex * 2u;
        ivec2 uv_base = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy) - 1;

        copyToShared(uv_base, i_base + 0);
        copyToShared(uv_base, i_base + 1);

        memoryBarrierShared();
        barrier();
    #endif

    ivec2 uv_in = ivec2(gl_GlobalInvocationID.xy * RENDER_SCALE_F);
    ivec2 uv_out = ivec2(gl_GlobalInvocationID.xy);

    if (all(lessThan(uv_out, viewSize))) {
        float depth = texelFetch(TEX_DEPTH, uv_in, 0).r;
        uint metaData = texelFetch(TEX_GB_SPECULAR, uv_in, 0).g;
        uint matId = uint(unpackUnorm4x8(metaData).a * 255.0 + 0.5);
        bool isHand = matId == MAT_HAND;

        vec2 texcoord = (uv_out + 0.5) / viewSize;
        vec3 ndcPos = screenToNdc(vec3(texcoord, depth));
        vec3 ndcPosPrev = reproject(ndcPos, isHand);
        vec2 texcoord_prev = ndcPosPrev.xy * 0.5 + 0.5;

        vec2 screenVelocity = texcoord - texcoord_prev;

        #ifdef TAA_SHARPEN_HISTORY
            vec4 lastColor = sample_CatmullRom_RGBA(texTAA_prev, texcoord_prev, viewSize);
        #else
            vec4 lastColor = texture(texTAA_prev, texcoord_prev);
        #endif

        float mixRate = TAA_MaxAccumFrames;//clamp(lastColor.a, 0.0, TAA_MaxAccumFrames);

        if (saturate(texcoord_prev) != texcoord_prev) mixRate = 0.0;

        const ivec2 offsets[] = ivec2[8](
            ivec2(-1,-1),
            ivec2( 0,-1),
            ivec2( 1,-1),
            ivec2(-1, 0),
            ivec2( 1, 0),
            ivec2(-1, 1),
            ivec2( 0, 1),
            ivec2( 1, 1));

        #if RENDER_SCALE == 0
            ivec2 luv = ivec2(gl_LocalInvocationID.xy) + 1;
            vec3 in0 = sharedBuffer[getSharedIndex(luv)];
        #else
            vec2 txs = texcoord * RENDER_SCALE_F;
            vec3 in0 = texture(TEX_FINAL, txs).rgb;
        #endif

        vec3 color_min = in0;
        vec3 color_max = in0;
//        vec3 m1 = vec3(0.0);
//        vec3 m2 = vec3(0.0);

        for (int i = 0; i < 8; i++) {
            #if RENDER_SCALE == 0
                vec3 in1 = sharedBuffer[getSharedIndex(luv + offsets[i])];
            #else
                vec3 in1 = textureOffset(TEX_FINAL, txs, offsets[i]).rgb;
            #endif

            color_min = min(color_min, in1);
            color_max = max(color_max, in1);
//            m1 += in1;
//            m2 += _pow2(in1);
        }

//        // Compute mean and standard deviation
//        const float weightSum = 9.0;
//        vec3 mu = m1 / weightSum;
//        vec3 sigma = sqrt(max((m2 / weightSum) - _pow2(mu), vec3(0.0)));
//
//        // Clip history color to the local neighborhood standard deviation bounds
//        float gamma = 0.5; // Controls how strict the color clipping is
//        vec3 bMin = mu - gamma * sigma;
//        vec3 bMax = mu + gamma * sigma;
//        vec3 historyColor = clamp(lastColor.rgb, bMin, bMax);
//
//        // 5. Blend Current and History (Temporal Accumulation)
//        // A standard FSR blend factor relies on motion magnitude
//        float motionLength = length(screenVelocity);
//        float alpha = clamp(0.05 + motionLength * 4.0, 0.02, 0.85); // Adjust alpha dynamically
//
//        vec3 colorFinal = mix(historyColor, in0, alpha);




        vec3 antialiased = mix(lastColor.rgb, in0, 1.0 / (mixRate + 1.0));
        vec3 colorFinal = clamp(antialiased, color_min, color_max);

        imageStore(imgTAA, uv_out, vec4(colorFinal, mixRate + 1.0));
    }
}
