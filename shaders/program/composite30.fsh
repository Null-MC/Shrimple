#define RENDER_COMPOSITE_POST
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/post/saturation.glsl"
#include "/lib/post/tonemap.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    vec3 color = texelFetch(BUFFER_FINAL, ivec2(gl_FragCoord.xy), 0).rgb;

    #if defined DH_COMPAT_ENABLED && !defined DEFERRED_BUFFER_ENABLED
        color = RGBToLinear(color);
    #endif

    ApplyPostProcessing(color);

    outFinal = color;
}
