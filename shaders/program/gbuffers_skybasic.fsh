#define RENDER_SKYBASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float viewHeight;
uniform float viewWidth;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float blindness;

#include "/lib/world/fog.glsl"

#ifdef TONEMAP_ENABLED
	#include "/lib/post/tonemap.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec3 color;
	if (starData.a > 0.5) {
		color = starData.rgb;
	}
	else {
		vec3 pos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0);
		pos = (gbufferProjectionInverse * vec4(pos, 1.0)).xyz;
		color = GetFogColor(normalize(pos.xyz));
	}

	color *= 1.0 - blindness;

    #if defined TONEMAP_ENABLED && DYN_LIGHT_MODE != DYN_LIGHT_TRACED
        color = tonemap_Tech(color);
    #endif

    color = LinearToRGB(color);

	outColor0 = vec4(color, 1.0);
}
