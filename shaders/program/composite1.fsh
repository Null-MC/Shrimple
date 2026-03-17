#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_TRANSLUCENT_FINAL;
uniform sampler2D TEX_TRANSLUCENT_TINT;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    vec3 tint = texelFetch(TEX_TRANSLUCENT_TINT, uv, 0).rgb;
    vec4 color = texelFetch(TEX_TRANSLUCENT_FINAL, uv, 0);

    outFinal = mix(src * RGBToLinear(tint), color.rgb, color.a);
}
