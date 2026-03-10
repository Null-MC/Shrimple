#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec4 starData;
in vec3 localPos;


uniform float far;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float rainStrength;
uniform int renderStage;
uniform int isEyeInWater;
uniform vec3 sunLocalDir;
uniform ivec2 eyeBrightnessSmooth;

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;


void main() {
    vec4 color = vec4(0.0);

    if (renderStage == MC_RENDER_STAGE_STARS) {
        color = starData;
        color.rgb = RGBToLinear(color.rgb);
    }
    else {
        vec3 localViewDir = normalize(localPos);
        color.rgb = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);
        color.a = 1.0;
    }

    outFinal = color;
}
