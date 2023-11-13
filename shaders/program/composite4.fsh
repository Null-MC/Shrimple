#define RENDER_OPAQUE_SSAO
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex1;
uniform usampler2D BUFFER_DEFERRED_DATA;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec2 viewSize;
uniform vec2 pixelSize;

#include "/lib/sampling/noise.glsl"
#include "/lib/sampling/ign.glsl"


float GetSpiralOcclusion(const in vec2 uv, const in vec3 viewPos, const in vec3 viewNormal) {
    const float inv = rcp(EFFECT_SSAO_SAMPLES);
    const float rStep = inv * EFFECT_SSAO_RADIUS;

    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
    float rotatePhase = dither * TAU;

    float radius = rStep;
    vec2 offset;

    float ao = 0.0;
    int sampleCount = 0;
    for (int i = 0; i < EFFECT_SSAO_SAMPLES; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;

        radius += rStep;
        rotatePhase += GOLDEN_ANGLE;

        vec3 sampleViewPos = viewPos + vec3(offset, 0.0);
        vec3 sampleClipPos = unproject(gbufferProjection * vec4(sampleViewPos, 1.0)) * 0.5 + 0.5;
        //sampleClipPos = saturate(sampleClipPos);
        if (saturate(sampleClipPos) != sampleClipPos) continue;
        sampleCount++;

        float sampleClipDepth = textureLod(depthtex1, sampleClipPos.xy, 0.0).r;
        if (sampleClipDepth >= 1.0 - EPSILON) continue;

        sampleClipPos.z = sampleClipDepth;
        sampleViewPos = unproject(gbufferProjectionInverse * vec4(sampleClipPos * 2.0 - 1.0, 1.0));

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - EFFECT_SSAO_BIAS, 0.0) * (1.0 - EFFECT_SSAO_BIAS);
        float aoF = 1.0 - saturate(sampleDist / EFFECT_SSAO_RADIUS);
        ao += sampleNoLm;// * pow(aoF, 1.5);

    }

    ao = saturate(ao / max(sampleCount, 1));
    //ao = saturate(ao / EFFECT_SSAO_SAMPLES);

    //ao = smoothstep(0.0, rcp(EFFECT_SSAO_STRENGTH), ao);
    ao = 1.0 - pow(1.0 - ao, EFFECT_SSAO_STRENGTH);

    //ao *= EFFECT_SSAO_STRENGTH;
    //ao /= ao + 0.5;
    //ao = smoothstep(0.0, 0.2, ao);

    return ao * (1.0 - EFFECT_SSAO_MIN);
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAO;

void main() {
    float depth = textureLod(depthtex1, texcoord, 0).r;
    vec4 final = vec4(1.0);

    if (depth < 1.0) {
        vec3 clipPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(gbufferProjectionInverse * vec4(clipPos, 1.0));

        #ifdef DEFERRED_BUFFER_ENABLED
            uvec4 deferredData = texelFetch(BUFFER_DEFERRED_DATA, ivec2(gl_FragCoord.xy), 0);
            vec4 deferredTexture = unpackUnorm4x8(deferredData.a);
            vec3 texViewNormal = deferredTexture.rgb;

            if (any(greaterThan(texViewNormal, EPSILON3))) {
                texViewNormal = normalize(texViewNormal * 2.0 - 1.0);
                texViewNormal = mat3(gbufferModelView) * texViewNormal;
            }
        #else
            vec3 texViewNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
        #endif

        float occlusion = GetSpiralOcclusion(texcoord, viewPos, texViewNormal);

        //float distF = smoothstep(-1.0, 1.0, length(viewPos));
        final.a = 1.0 - occlusion;// * distF;
    }

    outAO = final;
}
