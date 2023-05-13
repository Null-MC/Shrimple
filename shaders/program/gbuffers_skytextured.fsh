#define RENDER_SKYTEXTURED
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

uniform sampler2D gtexture;

uniform int renderStage;

#ifdef IRIS_FEATURE_SSBO
    #include "/lib/buffers/scene.glsl"
#endif

#include "/lib/sampling/bayer.glsl"
#include "/lib/sampling/ign.glsl"

#include "/lib/world/sky.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    color.rgb = RGBToLinear(color.rgb) * WorldSkyBrightnessF;

    //color.a = saturate(length2(color.rgb) / sqrt(3.0));

    if (renderStage == MC_RENDER_STAGE_SUN) {
        #ifdef IRIS_FEATURE_SSBO
            color.rgb *= WorldSunLightColor;
        #else
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            color.rgb *= GetSkySunColor(localSunDirection);
        #endif

        //float horizonF = GetSkyHorizonF(localSunDirection.y);
        color.rgb *= 2.0 * smoothstep(-0.1, 0.1, localSunDirection.y);
    }

    //if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
    //    color.rgb *= 2.0;

    // #ifndef DEFERRED_BUFFER_ENABLED
    //     ApplyPostProcessing(color.rgb);
    // #endif

    // color.rgb += InterleavedGradientNoise(gl_FragCoord.xy) / 256.0;

    outColor0 = color;
}
