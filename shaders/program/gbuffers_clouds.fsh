#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec3 localPos;
    vec3 localNormal;
} vIn;


#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
#endif

#ifdef VOXY
    uniform sampler2D vxDepthTexOpaque;
#endif

uniform float near;
uniform float far;
uniform float farPlane;
uniform vec3 sunLocalDir;
uniform mat4 gbufferModelView;
uniform ivec2 eyeBrightnessSmooth;
uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
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
uniform vec2 viewSize;

uniform mat4 dhProjectionInverse;
uniform int vxRenderDistance;
uniform float dhNearPlane;
uniform float dhFarPlane;

#include "/lib/sampling/depth.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #include "/lib/sky-transmit.glsl"
    #include "/lib/sky-irradiance.glsl"

    #include "/lib/enhanced-lighting.glsl"
#endif


#include "_output.glsl"

void main() {
    #ifdef DISTANT_HORIZONS
        float depthDh = texelFetch(dhDepthTex0, ivec2(gl_FragCoord.xy), 0).r;

        if (depthDh > 0.0 && depthDh < 1.0) {
//            float depthDhL = linearizeDepth(depthDh * 2.0 - 1.0, dhNearPlane, dhFarPlane);
            vec2 texcoord = gl_FragCoord.xy / viewSize;
            vec3 dhViewPos = project(dhProjectionInverse, vec3(texcoord, depthDh)*2.0-1.0);
            vec3 viewPos = mul3(gbufferModelView, vIn.localPos);

            if (viewPos.z > dhViewPos.z) {discard; return;}
        }
    #elif defined(VOXY)
        float depthVoxy = texelFetch(vxDepthTexOpaque, ivec2(gl_FragCoord.xy), 0).r;

        if (depthVoxy > 0.0 && depthVoxy < 1.0) {
            float depthVoxyL = linearizeDepth(depthVoxy * 2.0 - 1.0, vxNearPlane, vxFarPlane);
            vec3 viewPos = mul3(gbufferModelView, vIn.localPos);

            if (-viewPos.z >= depthVoxyL) {discard; return;}
        }
    #endif

    float viewDist = length(vIn.localPos);
    vec3 localNormal = normalize(vIn.localNormal);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        vec4 color;
        color.rgb = RGBToLinear(vec3(0.776, 0.788, 0.831));
        color.a = mix(0.64, 0.96, rainStrength);

        vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
        vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);
        float NoLm = dot(localNormal, localSkyLightDir) * 0.4 + 0.6;
        color.rgb *= 0.1 * NoLm * skyLightColor;

        color.rgb += 0.8 * AmbientLightF * SampleSkyIrradiance(localNormal);

//        color.rgb *= 0.1;
    #else
        vec4 color = vIn.color;
        color.rgb = RGBToLinear(color.rgb);
    #endif

    float borderFogF = 0.0;//smoothstep(0.94 * far, far, viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogWaterColor(RGBToLinear(skyColor), RGBToLinear(fogColor), localViewDir);

    color.rgb = mix(color.rgb * color.a, fogColorFinal, fogF);

    outFinal = color;
//    outMeta = 0u;

    #ifdef VELOCITY_ENABLED
        // TODO: can this be hard-coded?
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_ENABLED
        //        vec3 viewNormal = mat3(gbufferModelView) * localNormal;
        outNormals = vec4(0.0);//vec4(OctEncode(localNormal), OctEncode(viewNormal));

        outSpecularMeta = uvec2(0u);
    #endif
}
