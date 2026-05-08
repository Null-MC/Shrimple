#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;


uniform float skyDayF;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 sunLocalDir;
uniform float weatherDensity;
uniform float weatherStrength;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int hasSkylight;
uniform vec2 viewSizeScaled;
uniform float blindness;

uniform int vxRenderDistance;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    #if OVERWORLD_SKY == SKY_ENHANCED && defined(WORLD_OVERWORLD)
        vec3 color = vec3(0.0);
        if (blindness > 0.0) {
            vec3 ndcPos = vec3(gl_FragCoord.xy / viewSizeScaled, 1.0) * 2.0 - 1.0;
            vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
            vec3 localViewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);

            vec3 skyColorL = RGBToLinear(skyColor);
            vec3 fogColorL = RGBToLinear(fogColor);
            color = GetSkyFogColor(skyColorL, fogColorL, sunLocalDir, localViewDir, weatherStrength, skyDayF);
        }

        outFinal = vec4(color, 1.0);
    #else
        outFinal = vec4(RGBToLinear(fogColor), 1.0);
    #endif
}
