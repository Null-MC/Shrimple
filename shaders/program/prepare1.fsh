#define RENDER_PREPARE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform vec3 fogColor;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
	vec3 color = fogColor * WorldSkyBrightnessF;
    color = RGBToLinear(color);

	outFinal = vec4(color, 1.0);
}
