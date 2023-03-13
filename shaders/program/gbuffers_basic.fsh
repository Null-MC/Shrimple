#define RENDER_BASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 skyColor;
uniform float far;

uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform int fogMode;

#if MC_VERSION >= 11700
    uniform float alphaTestRef;
#endif

#include "/lib/world/fog.glsl"


// #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
//     /* RENDERTARGETS: 1,2,3,4 */
//     layout(location = 0) out vec4 outColor;
//     layout(location = 1) out vec4 outNormal;
//     layout(location = 2) out vec4 outLighting;
//     layout(location = 3) out vec4 outFog;
// #else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
//#endif

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;
	
	color *= texture(lightmap, lmcoord);

    // #if DYN_LIGHT_MODE == DYN_LIGHT_TRACED
	//     color.a = 1.0;

    //     float fogF = GetVanillaFogFactor(vLocalPos);
    //     vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
    //     fogColorFinal = LinearToRGB(fogColorFinal);

    //     outColor = color;
    //     outNormal = vec4(0.0, 0.0, 0.0, 1.0);
    //     outLighting = vec4(lmcoord, 1.0, 1.0);
    //     outFog = vec4(fogColorFinal, fogF);
    // #else
		outFinal = color;
	//#endif
}
