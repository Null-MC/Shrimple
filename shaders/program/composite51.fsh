//#define RENDER_COMPOSITE_SHARPEN
#define RENDER_COMPOSITE
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D BUFFER_FINAL;

uniform vec2 pixelSize;

#include "/lib/sampling/bayer.glsl"


#define SHARPENING 0.5 //[0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.3 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.4 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0 ]


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    // borrowed from chocapic

    vec3 col = texture2D(BUFFER_FINAL, texcoord).rgb;
    vec2 hp = 0.5 * pixelSize;

    //Weights : 1 in the center, 0.5 middle, 0.25 corners
    vec3 albedoCurrent1 = texture2D(BUFFER_FINAL, texcoord + vec2(hp.x,hp.y)).rgb;
    vec3 albedoCurrent2 = texture2D(BUFFER_FINAL, texcoord + vec2(hp.x,-hp.y)).rgb;
    vec3 albedoCurrent3 = texture2D(BUFFER_FINAL, texcoord + vec2(-hp.x,-hp.y)).rgb;
    vec3 albedoCurrent4 = texture2D(BUFFER_FINAL, texcoord + vec2(-hp.x,hp.y)).rgb;
    vec3 neighborSum = albedoCurrent1 + albedoCurrent2 + albedoCurrent3 + albedoCurrent4;

    vec3 m1 = -0.5/3.5*col + neighborSum/3.5;
    vec3 std = abs(col - m1)
        + abs(albedoCurrent1 - m1)
        + abs(albedoCurrent2 - m1)
        + abs(albedoCurrent3 - m1)
        + abs(albedoCurrent4 - m1);

    float contrast = 1.0 - luminance(std)/5.0;
    col = col*(1.0 + SHARPENING*contrast) - SHARPENING/(1.0-0.5/3.5) * contrast*(m1 - 0.5/3.5*col);

//    float dither = GetScreenBayerValue(ivec2(2,1));
//    color += (dither - 0.5) / 255.0;

    outFinal = col;
}
