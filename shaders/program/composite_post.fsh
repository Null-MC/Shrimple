#define RENDER_COMPOSITE_POST
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

uniform ivec2 eyeBrightnessSmooth;
uniform float nightVision;
uniform float playerMood;

uniform bool hideGUI;

#if MC_VERSION >= 11900
    uniform float darknessFactor;
    uniform float darknessLightFactor;
#endif

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/bayer.glsl"

#include "/lib/utility/matrix.glsl"

#include "/lib/post/saturation.glsl"
#include "/lib/post/tonemap.glsl"
#include "/lib/post/exposure.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec3 color = texelFetch(BUFFER_FINAL, ivec2(gl_FragCoord.xy), 0).rgb;

    ApplyPostExposure(color);

    ApplyPostGrading(color);

    ApplyPostTonemap(color);

    color = LinearToRGB(color, GAMMA_OUT);

    float dither = GetScreenBayerValue(ivec2(2,1));
    color += (dither - 0.5) / 255.0;

    outFinal = color;
}
