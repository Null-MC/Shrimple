#define RENDER_SHADOW
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 gTexcoord;
in vec4 gColor;
flat in uint gBlockId;

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
	flat in vec2 gShadowTilePos;
#endif

uniform sampler2D gtexture;

uniform int renderStage;

#if MC_VERSION >= 11700
	uniform float alphaTestRef;
#endif

#include "/lib/blocks.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
	#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
		vec2 p = gl_FragCoord.xy / shadowMapSize - gShadowTilePos;
		if (clamp(p, vec2(0.0), vec2(0.5)) != p) discard;
	#endif

	vec4 color = texture(gtexture, gTexcoord);

	float alphaF = renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT
		? (1.5/255.0) : alphaTestRef;

	if (color.a < alphaF) {
		discard;
		return;
	}

	color.rgb = RGBToLinear(color.rgb * gColor.rgb);

	#if defined SHADOW_COLORED && defined SHADOW_COLOR_BLEND
		color.rgb = mix(color.rgb, vec3(1.0), _pow2(color.a));
	#endif

	color.rgb = LinearToRGB(color.rgb);

	if (gBlockId == BLOCK_WATER) {
	    color = vec4(0.90, 0.94, 0.96, 0.0);
	}
	
	outColor0 = color;
}
