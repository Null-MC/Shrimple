#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef LOD_ENABLED
    #define TEX_LOD_DEPTH texDepthLod_opaque
    #define MAT_PROJ_INV matProjInv
    #define MAT_PROJ matProj
#else
    #define MAT_PROJ_INV gbufferProjectionInverse
    #define MAT_PROJ gbufferProjection
#endif

#define TEX_DEPTH depthtex1

in vec2 v_texcoord;


uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_LOD_DEPTH;
uniform sampler2D TEX_GB_NORMALS;

uniform float far;
uniform float near;
uniform int frameCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec2 taa_offset = vec2(0.0);

#include "/lib/octohedral.glsl"
#include "/lib/ign.glsl"

#ifdef LOD_ENABLED
    #include "/lib/lod-projection.glsl"
#endif


float GetSpiralOcclusion(const in vec3 viewPos, const in vec3 viewNormal) {
    vec2 seed = gl_FragCoord.xy;

    #ifdef TAA_ENABLED
        seed += vec2(71.83, 83.71) * (frameCounter % 16);
    #endif

    float dither = InterleavedGradientNoise(seed);

    float max_radius = length(viewPos) * 0.08;
    max_radius = min(max_radius, 4.0);

    float rotatePhase = dither * (PI * 2.0);
    const float rStep = max_radius / float(SSAO_SAMPLES);

    #ifdef LOD_ENABLED
        mat4 matProj = GetLodProjection(gbufferProjection, near);
        mat4 matProjInv = GetLodProjectionInverse(gbufferProjectionInverse, near);
    #endif

    float accumLitF = 0.0;
    int sampleCount = 0;
    float radius = rStep;
    for (int i = 1; i <= SSAO_SAMPLES; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;

        radius += rStep;
        rotatePhase += GoldenAngle;

        vec3 sampleViewPos = viewPos + vec3(offset, -0.02);

        vec3 sampleNdcPos = project(MAT_PROJ, sampleViewPos);
        vec3 sampleScreenPos = ndcToScreen(sampleNdcPos);
        sampleScreenPos = saturate(sampleScreenPos);

        vec2 sampleCoord = sampleScreenPos.xy * RENDER_SCALE_F;

        #ifdef LOD_ENABLED
            sampleScreenPos.z = texture(TEX_LOD_DEPTH, sampleCoord).r;
            bool isSky = sampleScreenPos.z <= 0.0;
        #else
            sampleScreenPos.z = texture(TEX_DEPTH, sampleCoord).r;
            bool isSky = sampleScreenPos.z >= 1.0;
        #endif

        if (isSky) {
            accumLitF += 1.0;
            continue;
        }

        sampleNdcPos = screenToNdc(sampleScreenPos);
        sampleViewPos = project(MAT_PROJ_INV, sampleNdcPos);

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleOcclusion = step(0.04, dot(viewNormal, sampleNormal));
        accumLitF += 1.0 - sampleOcclusion;
    }

    return accumLitF / SSAO_SAMPLES;
}


/* RENDERTARGETS: 7 */
layout(location = 0) out float outOcclusion;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    float occlusion = 1.0;
    bool hasAO = true;

    #ifdef LOD_ENABLED
        float depth = texelFetch(TEX_LOD_DEPTH, uv, 0).r;
        if (depth <= 0.0) hasAO = false;
    #else
        float depth = texelFetch(TEX_DEPTH, uv, 0).r;
        if (depth >= 1.0) hasAO = false;
    #endif

    if (hasAO) {
        vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);

        vec3 screenPos = vec3(v_texcoord, depth);

//        #ifdef TAA_ENABLED
//             screenPos.xy -= taa_offset;
//        #endif

        vec3 ndcPos = screenToNdc(screenPos);

        // don't fix hand depth, not needed

        #ifdef LOD_ENABLED
            mat4 matProjInv = GetLodProjectionInverse(gbufferProjectionInverse, near);
        #endif

        vec3 viewPos = project(MAT_PROJ_INV, ndcPos);

        #if LIGHTING_RESOLUTION > 0
            vec3 snapOffset = fract(cameraPosition);
            vec3 localGeoNormal = OctDecode(normalData.xy);
            vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

            localPos = (localPos + snapOffset) * LIGHTING_RESOLUTION;
            localPos += 0.99*localGeoNormal;
            localPos = floor(localPos) + 0.5;
            localPos = localPos / LIGHTING_RESOLUTION - snapOffset;

            viewPos = mul3(gbufferModelView, localPos);
        #endif

        #if SSAO_MODE == SSAO_LOD
            #ifdef DISTANT_HORIZONS
                float viewDist = length(viewPos);
                if (viewDist < dh_clipDistF * far) hasAO = false;
            #endif

            #ifdef VOXY
                float v_depth = texelFetch(TEX_DEPTH, uv, 0).r;
                if (v_depth < 1.0) hasAO = false;
            #endif
        #endif

        if (hasAO) {
            vec3 viewTexNormal = OctDecode(normalData.zw);

            occlusion = GetSpiralOcclusion(viewPos, viewTexNormal);
            occlusion = saturate(occlusion);
        }
    }

    outOcclusion = LinearToRGB(occlusion);
}
