#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


layout(rgba16f) uniform image2D IMG_FINAL;

uniform sampler2D TEX_FINAL;

uniform vec2 viewSize;


vec3 tonemap_Reinhard(const in vec3 colorL) {
    const float wp = 40.0;

    float lum = luminance(colorL);
    float tgt = lum * (lum/wp + 1.0) / (lum + 0.75);
//    float tgt = lum / (lum + 0.75);
    return colorL * (tgt / lum);
}

vec3 tonemap_Lottes(const in vec3 colorL) {
    const vec3 a = vec3(1.3); // contrast
    const vec3 d = vec3(0.977); // shoulder
    const vec3 hdrMax = vec3(8.0);
    const vec3 midIn = vec3(0.48);
    const vec3 midOut = vec3(0.48);

    const vec3 b =
        (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    const vec3 c =
        (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return pow(colorL, a) / (pow(colorL, a * d) * b + c);
}


void main() {
    if (!all(lessThan(gl_GlobalInvocationID.xy, viewSize))) return;

    vec3 color = texelFetch(TEX_FINAL, ivec2(gl_GlobalInvocationID.xy), 0).rgb;

    #ifdef TONEMAP_ENABLED
//        color = tonemap_Reinhard(color);
        color = tonemap_Lottes(color);
    #endif

    color = LinearToRGB(color);

    imageStore(IMG_FINAL, ivec2(gl_GlobalInvocationID.xy), vec4(color, 1.0));
}
