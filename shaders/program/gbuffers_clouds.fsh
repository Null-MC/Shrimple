#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec3 localPos;
    vec3 localNormal;
} vIn;


#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

uniform float near;
uniform float far;
uniform float farPlane;
uniform vec3 sunLocalDir;
uniform mat4 gbufferModelView;
uniform ivec2 eyeBrightnessSmooth;
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

#include "/lib/sampling/depth.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"


#include "_output.glsl"

void main() {
    #ifdef DISTANT_HORIZONS
//        float depthDh = texelFetch(dhDepthTex0, ivec2(gl_FragCoord.xy), 0).r;
//        float depthDhL = linearizeDepth(depthDh * 2.0 - 1.0, dhNearPlane, dhFarPlane);
//
//        vec3 viewPos = mul3(gbufferModelView, vIn.localPos);
//
//        if (-viewPos.z >= depthDhL) {
//            discard;
//            return;
//        }


        float depthDh = texelFetch(dhDepthTex0, ivec2(gl_FragCoord.xy), 0).r;
        if (depthDh > 0.0 && depthDh < 1.0) {
            float depthDhL = linearizeDepth(depthDh * 2.0 - 1.0, dhNearPlane, dhFarPlane);
            float depthL = linearizeDepth(gl_FragCoord.z * 2.0 - 1.0, near, farPlane);

            if (depthL >= depthDhL) {discard; return;}
        }
    #endif

    vec4 color = vIn.color;
    color.rgb = RGBToLinear(color.rgb);

    float viewDist = length(vIn.localPos);
    vec3 localNormal = normalize(vIn.localNormal);

    float borderFogF = 0.0;//smoothstep(0.94 * far, far, viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    outFinal = color;

    #ifdef DEFERRED_NORMAL_ENABLED
        vec3 viewNormal = mat3(gbufferModelView) * localNormal;

        outNormal = uvec2(
            packUnorm2x16(OctEncode(localNormal)),
            packUnorm2x16(OctEncode(viewNormal)));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outAlbedoSpecular = uvec2(0u);
    #endif
}
