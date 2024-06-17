#define RENDER_PREPARE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform vec3 fogColor;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
	vec3 color = RGBToLinear(fogColor);// * Sky_BrightnessF;

	outFinal = vec4(color, 1.0);
}
