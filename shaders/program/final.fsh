#include "/lib/constants.glsl"
#include "/lib/common.glsl"

uniform sampler2D radiosity_position;

in vec2 texcoord;

uniform sampler2D TEX_FINAL;

//uniform sampler2D texCloudShadow;

#if DEBUG_VIEW == DEBUG_VIEW_SSAO
    uniform sampler2D TEX_SSAO;
#elif DEBUG_VIEW == DEBUG_VIEW_IRRADIANCE
    uniform sampler3D texSkyIrradiance;
    uniform sampler2D texSkyTransmit;
#elif DEBUG_VIEW == DEBUG_VIEW_BLOOM
    uniform sampler2D TEX_BLOOM_TILES;
#endif

#ifdef PHOTONICS_LIGHT_DEBUG
    uniform usampler2D texLightDebug;
#endif

uniform vec2 viewSize;
uniform int frameCounter;
uniform float rainStrength;
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

        int binStart = load_light_offset(rt_camera_position);
        int binCount = light_registry_array[binStart];

        printString((_C, _u, _r, _r, _e, _n, _t, _space, _b, _i, _n, _colon, _space));
        printInt(binCount);
        printLine();

        endText(color);


        vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(320, 240);
        if (saturate(tex) == tex) {
            int counter = int(texture(texLightDebug, tex).r);
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
    #endif

//    vec2 tex = (gl_FragCoord.xy - 8.5) / vec2(900);
//    if (saturate(tex) == tex) {
//        color = texture(texCloudShadow, fract(tex*3.0)).rrr;
//    }

    color += (GetBayerValue(ivec2(gl_FragCoord.xy)) - 0.5) / 255.0;

    gl_FragData[0] = vec4(color, 1.0);
}
