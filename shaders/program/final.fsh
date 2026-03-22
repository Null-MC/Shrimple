#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;

#if DEBUG_VIEW == DEBUG_VIEW_SSAO
    uniform sampler2D TEX_SSAO;
#elif DEBUG_VIEW == DEBUG_VIEW_IRRADIANCE
    uniform sampler3D texSkyIrradiance;
    uniform sampler2D texSkyTransmit;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOOM
    uniform sampler2D TEX_BLOOM_TILES;
#elif DEBUG_VIEW == DEBUG_VIEW_WATER
    uniform sampler2D texWaterHeight;
    uniform sampler2D TEX_WATER_NORMAL;
#endif

//uniform sampler2D TEX_TRANSLUCENT_TINT;

uniform vec2 viewSize;
uniform int frameCounter;
uniform float rainStrength;
uniform float farPlane;
uniform float far2;
uniform float far3;

#include "/lib/sampling/bayer.glsl"

#if defined(DEBUG_FAR)
    #include "/lib/text.glsl"
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

    #if DEBUG_VIEW == DEBUG_VIEW_SSAO
        vec2 tex = (gl_FragCoord.xy - 8) / (viewSize * 0.2);
        if (saturate(tex) == tex) {
            color = texture(TEX_SSAO, tex).rrr;
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_IRRADIANCE
        const vec2 irradianceSize = vec2(24, 6);
        vec2 tex = (gl_FragCoord.xy - 8) / (irradianceSize*8.0);
        if (saturate(tex) == tex) {
            vec3 uv = vec3(
                tex.x,
                floor(tex.y*6.0)/6.0,
                rainStrength * 0.50 + 0.25);
            color = texture(texSkyIrradiance, uv).rgb;
            color = LinearToRGB(color);
        }

        const vec2 transmitSize = vec2(256, 64);
        vec2 tex2 = (gl_FragCoord.xy - vec2(irradianceSize.x*8.0 + 16.0, 8.0)) / transmitSize;
        if (saturate(tex2) == tex2) {
            color = texture(texSkyTransmit, tex2).rgb;
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_BLOOM
        vec2 tex = (gl_FragCoord.xy - 8.0) / (viewSize * 0.2);
//        vec2 tex = gl_FragCoord.xy / viewSize;
        if (saturate(tex) == tex) {
            color = texture(TEX_BLOOM_TILES, tex).rgb;

            #ifdef TONEMAP_ENABLED
                float lum = luminance(color);
                float tgt = lum / (lum + 0.75);
                color *= tgt / lum;
            #endif

            color = LinearToRGB(color);
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_WATER
        vec2 tex = (gl_FragCoord.xy - 8) / (256.0);
        if (saturate(tex) == tex) {
            color = texture(texWaterHeight, tex).rgb;
        }

        vec2 tex2 = (gl_FragCoord.xy - vec2(272, 8)) / (256.0);
        if (saturate(tex2) == tex2) {
            color = texture(TEX_WATER_NORMAL, tex2).rgb;
        }
    #endif

//    vec2 tex = (gl_FragCoord.xy - 8) / vec2(320, 240);
//    if (saturate(tex) == tex) {
//        color = texture(TEX_TRANSLUCENT_TINT, tex).rgb;
//    }


    color += (GetBayerValue(ivec2(gl_FragCoord.xy)) - 0.5) / 255.0;

    gl_FragData[0] = vec4(color, 1.0);
}
