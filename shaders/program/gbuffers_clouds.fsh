#define RENDER_CLOUDS
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec4 vColor;
in float vDist;

uniform float fogStart;
uniform float fogEnd;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

float linear_fog_fade(const in float dist, const in float start, const in float end) {
    return 1.0;
}

void main() {
    float newWidth = (fogEnd - fogStart) * 4.0;
    float fade = linear_fog_fade(vDist, fogStart, fogStart + newWidth);
    outColor0 = vec4(vColor.rgb, vColor.a * fade);
}
