#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

uniform sampler2D gtexture;

uniform int renderStage;

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/post/saturation.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    color.rgb = RGBToLinear(color.rgb) * WorldSkyBrightnessF;

    color.a = length2(color.rgb) / sqrt(3.0);

    //if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
    //    color.rgb *= 2.0;

    ApplyPostProcessing(color.rgb);

    color.rgb += InterleavedGradientNoise(gl_FragCoord.xy) / 255.0;

    outColor0 = color;
}
