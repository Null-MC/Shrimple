#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/common.glsl"
#include "/lib/constants.glsl"

varying vec2 texcoord;
varying vec4 glcolor;


uniform sampler2D gtexture;

//#include "/lib/world/fog.glsl"

#ifdef TONEMAP_ENABLED
	#include "/lib/post/tonemap.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec4 color = texture(gtexture, texcoord) * glcolor;

    #ifdef TONEMAP_ENABLED
	    color.rgb = RGBToLinear(color.rgb);
        color.rgb = tonemap_Tech(color.rgb);
	    color.rgb = LinearToRGB(color.rgb);
    #endif

	outColor0 = color;
}
