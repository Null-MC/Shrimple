#include "/lib/constants.glsl"
#include "/lib/common.glsl"


in vec2 texcoord;

uniform sampler2D TEX_FINAL;

//uniform sampler2D texCloudShadow;

#if DEBUG_VIEW == DEBUG_VIEW_SSAO
    uniform sampler2D TEX_SSAO;
#endif

#ifdef PHOTONICS_LIGHT_DEBUG
    uniform usampler2D texLightDebug;
#endif

//uniform sampler2D texSkyIrradiance;

uniform vec2 viewSize;
uniform int frameCounter;
uniform float farPlane;
uniform float far2;
uniform float far3;

#include "/lib/sampling/bayer.glsl"

#if defined(DEBUG_FAR) || defined(PHOTONICS_LIGHT_DEBUG)
    #include "/lib/text.glsl"
#endif

#ifdef PHOTONICS_LIGHT_DEBUG
    #include "/photonics/photonics.glsl"
#endif


void main() {
    vec3 color = texelFetch(TEX_FINAL, ivec2(gl_FragCoord.xy), 0).rgb;

    #ifdef DEBUG_FAR
        beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewSize.y/2 - 24));

        text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
        text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);

        printString((_F, _a, _r, _colon, _space, _space));
        printFloat(farPlane);
        printLine();

        printString((_F, _a, _r, _2, _colon, _space));
        printFloat(far2);
        printLine();

        printString((_F, _a, _r, _3, _colon, _space));
        printFloat(far3);
        printLine();

        endText(color);
    #endif

    #ifdef PHOTONICS_LIGHT_DEBUG
        beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewSize.y/2 - 24));

        text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
        text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);

        printString((_L, _i, _g, _h, _t, _s, _colon, _space));
        printUnsignedInt(ph_light_count);
        printLine();

        endText(color);


        vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(320, 240);
        if (saturate(tex) == tex) {
            int counter = int(textureLod(texLightDebug, tex, 0).r);
            if (counter > 0) {
                color = mix(vec3(0,0,1), vec3(0,1,0), saturate(counter/128.0));
                color = mix(color, vec3(1,0,0), saturate((counter-128)/128.0));
            }
            else {
                color = vec3(0.0);
            }
        }
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_SSAO
        vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(320, 240);
        if (saturate(tex) == tex) {
            color = textureLod(TEX_SSAO, tex, 0).rrr;
        }
    #endif

//    vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(900);
//    if (saturate(tex) == tex) {
//        color = textureLod(texCloudShadow, fract(tex*3.0), 0).rrr;
//    }

//    vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(96, 24);
//    if (saturate(tex) == tex) {
//        color = textureLod(texSkyIrradiance, tex, 0).rgb;
//    }

    color += (GetBayerValue(ivec2(gl_FragCoord.xy)) - 0.5) / 255.0;

    gl_FragData[0] = vec4(color, 1.0);
}
