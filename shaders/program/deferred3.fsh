#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

in vec2 texcoord;


uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_GI_COLOR;
uniform usampler2D TEX_TEX_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;

uniform vec2 viewSize;
uniform mat4 gbufferProjectionInverse;

#include "/lib/octohedral.glsl"


const int ATrousLevel = 0;
const int ATrous_StepWidth = (1 << ATrousLevel);

#define W(x) (x/256.0)

const float atrousKernel[25] = float[](
    W( 1), W( 4), W( 6), W( 4), W( 1),
    W( 4), W(16), W(24), W(16), W( 4),
    W( 6), W(24), W(36), W(24), W( 6),
    W( 4), W(16), W(24), W(16), W( 4),
    W( 1), W( 4), W( 6), W( 4), W( 1));

const ivec2 atrousOffsets[25] = ivec2[](
    ivec2(-2, -2), ivec2(-1, -2), ivec2(0, -2), ivec2(1, -2), ivec2(2, -2),
    ivec2(-2, -1), ivec2(-1, -1), ivec2(0, -1), ivec2(1, -1), ivec2(2, -1),
    ivec2(-2,  0), ivec2(-1,  0), ivec2(0,  0), ivec2(1,  0), ivec2(2,  0),
    ivec2(-2,  1), ivec2(-1,  1), ivec2(0,  1), ivec2(1,  1), ivec2(2,  1),
    ivec2(-2,  2), ivec2(-1,  2), ivec2(0,  2), ivec2(1,  2), ivec2(2,  2));

vec3 atrous_GetTexNormal(const in ivec2 uv) {
    uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
    return OctDecode(unpackUnorm2x16(reflectNormalData));
}

vec3 atrous_GetViewPosition(const in ivec2 uv) {
    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    vec3 clipPos = vec3(uv / viewSize, depth) * 2.0 - 1.0;
    return project(gbufferProjectionInverse, clipPos);
}

vec3 filter_ATrous(const in vec2 texcoord) {
    ivec2 uv = ivec2(texcoord * viewSize);

//    vec3 cval = texelFetch(TEX_GI_COLOR, uv, 0).rgb;
//    return cval;

    vec3 nval = atrous_GetTexNormal(uv);
    vec3 pval = atrous_GetViewPosition(uv);

//    const float c_phi = 0.1;
    const float n_phi = 100.0;
    const float p_phi = 100.0;

    float total_weight = 0.0;
    vec3 sum = vec3(0.0);

    for (int i = 0; i < 25; i++) {
        ivec2 sample_uv = atrousOffsets[i] * ATrous_StepWidth + uv;

        vec4 ctmp = texelFetch(TEX_GI_COLOR, sample_uv, 0);

        // scale weight by history counter
        //ctmp.rgb *= saturate(ctmp.a * 0.5);

        // float3 t = cval - ctmp;
        // float dist2 = dot(t,t);
        // float c_w = 1.0;//min(exp(-(dist2)/c_phi), 1.0);

        vec3 ntmp = atrous_GetTexNormal(sample_uv);
        float n_w = min(exp(-lengthSq(nval - ntmp) * n_phi), 1.0);

        vec3 ptmp = atrous_GetViewPosition(sample_uv);
        float p_w = min(exp(-lengthSq(pval - ptmp) * p_phi), 1.0);

        // float kernel_weight = c_w * n_w * p_w * atrousKernel[i];
        float kernel_weight = n_w * p_w * atrousKernel[i];
        sum += ctmp.rgb * kernel_weight;
        total_weight += kernel_weight;
    }

    return sum / max(total_weight, EPSILON);
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;

    vec3 lighting = filter_ATrous(texcoord);

    vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
    lighting *= RGBToLinear(reflectDataR.rgb);

    outFinal = src + lighting;
}
