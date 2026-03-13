#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
//    vec3 localNormal;
} vIn;


uniform sampler2D gtexture;

uniform float near;
uniform float far;
uniform float farPlane;
uniform vec3 sunLocalDir;
uniform mat4 gbufferModelView;
uniform ivec2 eyeBrightnessSmooth;
uniform int renderStage;
uniform int isEyeInWater;
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

//#include "/lib/sampling/depth.glsl"
//#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


#include "_output.glsl"

void main() {
    vec4 color = texture(gtexture, vIn.texcoord) * vIn.color;
    color.rgb = RGBToLinear(color.rgb);

    #ifdef MATERIAL_PBR_ENABLED
        color.rgb *= MATERIAL_EMISSION_SCALE;
    #endif

    float viewDist = length(vIn.localPos);
//    vec3 localNormal = normalize(vIn.localNormal);

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    outFinal = color;

    #ifdef DEFERRED_NORMAL_ENABLED
        outGeoNormal = 0u;
        outTexNormal = 0u;
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outReflectSpecular = uvec2(0u);
    #endif
}
