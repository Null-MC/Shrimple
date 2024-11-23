#define RENDER_FINAL
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;

#ifdef DISTANT_HORIZONS
	uniform float dhFarPlane;
#endif

#include "/lib/sampling/bayer.glsl"

#ifdef EFFECT_FXAA_ENABLED
	#include "/lib/effects/fxaa.glsl"
#endif

#ifndef IS_IRIS
	#include "/lib/utility/iris.glsl"
#endif


void main() {
	#ifdef EFFECT_FXAA_ENABLED
		vec3 color = FXAA(texcoord);
	#else
		vec3 color = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;
	#endif

    color += (GetScreenBayerValue(ivec2(2,1)) - 0.5) / 255.0;

	#ifndef IS_IRIS
		drawWarning(color);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}
