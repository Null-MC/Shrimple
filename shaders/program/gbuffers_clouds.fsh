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

float linear_fog_fade(const in float vertexDistance, const in float fogStart, const in float fogEnd) {
    if (vertexDistance <= fogStart) return 1.0;
    else if (vertexDistance >= fogEnd) return 0.0;

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

void main() {
    float newWidth = (fogEnd - fogStart) * 4.0;
    float fade = linear_fog_fade(vDist, fogStart, fogStart + newWidth);
    outColor0 = vec4(vColor.rgb, vColor.a * fade);
}
