#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 texcoord;

uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
	uniform mat4 shadowModelView;
	uniform float near;
	uniform float far;
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
	#if DEBUG_SHADOW_BUFFER == 1
		vec4 shadowColor = textureLod(shadowcolor0, texcoord, 0);
		//shadowColor.rgb = mix(shadowColor.rgb, vec3(0.0), pow2(shadowColor.a));
		vec3 color = shadowColor.rgb;
	#elif DEBUG_SHADOW_BUFFER == 2
		vec3 color = textureLod(shadowtex0, texcoord, 0).rrr;
	#elif DEBUG_SHADOW_BUFFER == 3
		vec3 color = textureLod(shadowtex1, texcoord, 0).rrr;
	#else
		const vec3 color = vec3(0.0);
	#endif

	outColor0 = vec4(color, 1.0);
}
