#define RENDER_PREPARE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform vec3 fogColor;

#include "/lib/sampling/bayer.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
	vec3 color = RGBToLinear(fogColor) * WorldBrightnessF;
    ApplyPostProcessing(color);
	outFinal = vec4(color, 1.0);
}
