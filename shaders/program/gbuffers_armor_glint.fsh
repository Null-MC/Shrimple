#define RENDER_ARMOR_GLINT
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

uniform sampler2D lightmap;
uniform sampler2D gtexture;


#if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
    /* RENDERTARGETS: 1 */
    layout(location = 0) out vec4 outDeferredColor;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;
	
	color *= texture(lightmap, lmcoord);

    #if defined IRIS_FEATURE_SSBO && LIGHTING_MODE == LIGHTING_MODE_TRACED
        //float dither = (InterleavedGradientNoise() - 0.5) / 255.0;

        //float fogF = GetVanillaFogFactor(vLocalPos);

        //vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        //fogColorFinal = LinearToRGB(fogColorFinal);

        //float lightLevel = GetSceneBlockEmission(vBlockId);

        //uvec3 deferredPre;
        //deferredPre.r = packUnorm4x8(color);
        //deferredPre.g = packUnorm4x8(vec4(localNormal * 0.5 + 0.5, 1.0));
        //deferredPre.b = packUnorm4x8(vec4(lmcoord + dither, glcolor.a + dither, lightLevel));

        //uvec2 deferredPost;
        //deferredPost.r = packUnorm4x8(vec4(shadowColor, 1.0));
        //deferredPost.g = packUnorm4x8(vec4(fogColorFinal, fogF + dither));

        outDeferredColor = color;
    #else
		outFinal = color;
	#endif
}
