#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;

#if DEBUG_VIEW == DEBUG_VIEW_SKY
    uniform sampler3D texSkyIrradiance;
    uniform sampler2D texSkyTransmit;
#elif DEBUG_VIEW == DEBUG_VIEW_GBUFFER
    uniform sampler2D TEX_GB_COLOR;
    uniform sampler2D TEX_GB_NORMALS;
    uniform usampler2D TEX_GB_SPECULAR;
#elif DEBUG_VIEW == DEBUG_VIEW_SSAO
    uniform sampler2D TEX_SSAO;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOOM
    uniform sampler2D TEX_BLOOM_TILES;
#endif

uniform vec2 viewSize;
uniform int frameCounter;
uniform float rainStrength;
uniform float farPlane;
uniform float far2;
uniform float far3;

#include "/lib/sampling/bayer.glsl"
#include "/lib/octohedral.glsl"

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

    vec2 tex, tex2;
    #if DEBUG_VIEW == DEBUG_VIEW_SKY
        const vec2 irradianceSize = vec2(24, 6);
        tex = (gl_FragCoord.xy - 8) / (irradianceSize*8.0);
        if (saturate(tex) == tex) {
            vec3 uv = vec3(
                tex.x,
                floor(tex.y*6.0)/6.0,
                rainStrength * 0.50 + 0.25);

            color = texture(texSkyIrradiance, uv).rgb;
            color = LinearToRGB(color);
        }

        const vec2 transmitSize = vec2(256, 64);
        tex2 = (gl_FragCoord.xy - vec2(irradianceSize.x*8.0 + 16.0, 8.0)) / transmitSize;
        if (saturate(tex2) == tex2) {
            color = texture(texSkyTransmit, tex2).rgb;
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_GBUFFER
        vec2 thumbSize = viewSize * 0.2;
        tex = (gl_FragCoord.xy - 8) / thumbSize;
        if (saturate(tex) == tex) {
            color = texture(TEX_GB_COLOR, tex).rgb;
        }

        tex2 = (gl_FragCoord.xy - vec2(thumbSize.x + 16.0, 8)) / thumbSize;
        if (saturate(tex2) == tex2) {
            ivec2 uv = ivec2(tex2 * viewSize);
            color = OctDecode(texelFetch(TEX_GB_NORMALS, uv, 0).xy) * 0.5 + 0.5;
        }

        vec2 tex3 = (gl_FragCoord.xy - vec2(thumbSize.x*2.0 + 24.0, 8)) / thumbSize;
        if (saturate(tex3) == tex3) {
            ivec2 uv = ivec2(tex3 * viewSize);
            color = OctDecode(texelFetch(TEX_GB_NORMALS, uv, 0).zw) * 0.5 + 0.5;
        }

        vec2 tex4 = (gl_FragCoord.xy - vec2(thumbSize.x*3.0 + 32.0, 8)) / thumbSize;
        if (saturate(tex4) == tex4) {
            ivec2 uv = ivec2(tex4 * viewSize);
            uint metaData = texelFetch(TEX_GB_SPECULAR, uv, 0).g;
            color = unpackUnorm4x8(metaData).rgb;
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_SSAO
        tex = (gl_FragCoord.xy - 8) / (viewSize * 0.2);
        if (saturate(tex) == tex) {
            color = texture(TEX_SSAO, tex).rrr;
        }
    #elif DEBUG_VIEW == DEBUG_VIEW_BLOOM
        tex = (gl_FragCoord.xy - 8.0) / (viewSize * 0.2);
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
    #endif

//    tex = (gl_FragCoord.xy - 8) / vec2(320, 240);
//    if (saturate(tex) == tex) {
//        color = texture(texDepthLod_opaque, tex).rrr;
//        color = pow(color, vec3(0.2));
//    }


    color += (GetBayerValue(ivec2(gl_FragCoord.xy)) - 0.5) / 255.0;

    gl_FragData[0] = vec4(color, 1.0);
}
