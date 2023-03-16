#define RENDER_BASIC
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
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


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;
	
	color *= texture(lightmap, lmcoord);

    ApplyPostProcessing(color.rgb);
	outFinal = color;
}
