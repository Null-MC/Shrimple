#define RENDER_PREPARE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform vec3 fogColor;

#include "/lib/sampling/bayer.glsl"
#include "/lib/world/common.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#else
    #include "/lib/post/saturation.glsl"
#endif

#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
	vec3 color = RGBToLinear(fogColor) * WorldSkyBrightnessF;
    //ApplyPostProcessing(color);
	outFinal = vec4(color, 1.0);
}
