#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec3 localPos;
} vIn;


uniform float near;
uniform float far;
uniform float farPlane;
uniform vec3 sunLocalDir;
uniform mat4 gbufferModelView;
uniform ivec2 eyeBrightnessSmooth;
uniform int hasSkylight;
uniform int renderStage;
uniform int isEyeInWater;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;

uniform int vxRenderDistance;
uniform float dhNearPlane;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


#include "_output.glsl"

void main() {
    vec4 color = vIn.color;
    color.rgb = RGBToLinear(color.rgb);

    #ifdef MATERIAL_PBR_ENABLED
        color.rgb *= MATERIAL_EMISSION_SCALE;
    #endif

    color.rgb *= color.a;

    float viewDist = length(vIn.localPos);

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    outFinal = color;
    outAlbedo = vec4(1.0, 1.0, 1.0, 0.0);

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_ENABLED
        outNormals = vec4(0.0);
        outSpecularMeta = uvec2(0u);
    #endif
}
