#define RENDER_BEACONBEAM
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;

uniform sampler2D gtexture;

uniform mat4 gbufferModelView;
uniform vec3 sunPosition;
uniform vec3 upPosition;
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

#include "/lib/sampling/bayer.glsl"
#include "/lib/world/common.glsl"
#include "/lib/world/fog.glsl"
#include "/lib/post/tonemap.glsl"


#if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
    /* RENDERTARGETS: 1,2 */
    layout(location = 0) out uvec3 outDeferredPre;
    layout(location = 1) out uvec2 outDeferredPost;
#else
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 outFinal;
#endif

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;

    #if defined IRIS_FEATURE_SSBO && DYN_LIGHT_MODE == DYN_LIGHT_TRACED
        float fogF = GetVanillaFogFactor(vLocalPos);
        vec3 fogColorFinal = GetFogColor(normalize(vLocalPos).y);
        fogColorFinal = LinearToRGB(fogColorFinal);

        uvec3 deferredPre;
        deferredPre.r = packUnorm4x8(color);
        deferredPre.g = packUnorm4x8(vec4(vec3(0.0), 1.0));
        deferredPre.b = packUnorm4x8(vec4(1.0));

        uvec2 deferredPost;
        deferredPost.r = packUnorm4x8(vec4(1.0));
        deferredPost.g = packUnorm4x8(vec4(fogColorFinal, fogF));

        outDeferredPre = deferredPre;
        outDeferredPost = deferredPost;
    #else
        color.rgb = RGBToLinear(color.rgb);

        ApplyFog(color, vLocalPos);

        ApplyPostProcessing(color.rgb);
		outFinal = color;
	#endif
}
