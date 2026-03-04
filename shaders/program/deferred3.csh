#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(rgba16f) uniform writeonly image2D IMG_FINAL;

shared vec3 sharedColor[20*20];
shared vec3 sharedNormal[20*20];
shared vec3 sharedPosition[20*20];

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


int getSharedIndex(const in ivec2 uv) {
    return uv.y * 20 + uv.x;
}

void copyToShared(const in ivec2 uv_base, const in uint i_shared) {
    if (i_shared >= (20*20)) return;

    ivec2 uv = uv_base + ivec2(i_shared % 20, i_shared / 20);
    sharedColor[i_shared] = texelFetch(TEX_GI_COLOR, uv, 0).rgb;

    uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
    sharedNormal[i_shared] = OctDecode(unpackUnorm2x16(reflectNormalData));

    float depth = texelFetch(TEX_DEPTH, uv, 0).r;
    vec3 clipPos = vec3(uv / viewSize, depth) * 2.0 - 1.0;
    sharedPosition[i_shared] = project(gbufferProjectionInverse, clipPos);
}

vec3 filter_ATrous(const in ivec2 local_uv) {
    int i = getSharedIndex(local_uv);
    vec3 nval = sharedNormal[i];
    vec3 pval = sharedPosition[i];

    const float n_phi = 100.0;
    const float p_phi = 100.0;

    float total_weight = 0.0;
    vec3 sum = vec3(0.0);

    for (int i = 0; i < 25; i++) {
        int sample_i = getSharedIndex(local_uv + atrousOffsets[i]);

        vec3 ctmp = sharedColor[sample_i];

        vec3 ntmp = sharedNormal[sample_i];
        float n_w = min(exp(-lengthSq(nval - ntmp) * n_phi), 1.0);

        vec3 ptmp = sharedPosition[sample_i];
        float p_w = min(exp(-lengthSq(pval - ptmp) * p_phi), 1.0);

        float kernel_weight = n_w * p_w * atrousKernel[i];
        sum += ctmp * kernel_weight;
        total_weight += kernel_weight;
    }

    return sum / max(total_weight, EPSILON);
}


void main() {
    // preload shared memory
    int i_base = int(gl_LocalInvocationIndex) * 2;
    ivec2 uv_base = ivec2(gl_WorkGroupID.xy) * 16 - 2;

    copyToShared(uv_base, i_base + 0);
    copyToShared(uv_base, i_base + 1);

    barrier();

    // exit early if OOB
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, viewSize))) return;

    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;

    ivec2 local_uv = ivec2(gl_LocalInvocationID.xy) + 2;
    vec3 lighting = filter_ATrous(local_uv);

    vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
    lighting *= RGBToLinear(reflectDataR.rgb);

    imageStore(IMG_FINAL, uv, vec4(src + lighting, 1.0));
}
