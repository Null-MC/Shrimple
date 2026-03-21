#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_TRANSLUCENT_FINAL;
uniform sampler2D TEX_TRANSLUCENT_TINT;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#ifdef REFRACT_ENABLED
//    uniform sampler2D depthtex0;
//    uniform sampler2D depthtex1;
    uniform sampler2D TEX_NORMAL;
#endif

uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform int isEyeInWater;
uniform float viewWidth;
uniform float viewHeight;
uniform float nearPlane;
uniform float farPlane;

uniform vec3 sunLocalDir;
uniform float skyDayF;
uniform float weatherStrength;
uniform float weatherDensity;
uniform ivec2 eyeBrightnessSmooth;

uniform int vxRenderDistance;

#include "/lib/oklab.glsl"
#include "/lib/water.glsl"
#include "/lib/fog.glsl"

#ifdef REFRACT_ENABLED
    #include "/lib/sampling/depth.glsl"
    #include "/lib/octohedral.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec4 tintData = texelFetch(TEX_TRANSLUCENT_TINT, uv, 0);
    vec4 color = texelFetch(TEX_TRANSLUCENT_FINAL, uv, 0);
    float depthOpaque = texelFetch(depthtex1, uv, 0).r;
    float depthTranslucent = texelFetch(depthtex0, uv, 0).r;

    #ifdef REFRACT_ENABLED
//        float depthOpaque = texelFetch(depthtex1, uv, 0).r;
//        float depthTranslucent = texelFetch(depthtex0, uv, 0).r;
        vec4 normalData = texelFetch(TEX_NORMAL, uv, 0);

        vec2 coord = texcoord;
        if (depthTranslucent < depthOpaque) {
            const float eta = 1.0 / 1.33;
            vec3 geoLocalNormal = OctDecode(normalData.xy);
            vec3 texViewNormal = OctDecode(normalData.zw);
            vec3 geoViewNormal = mat3(gbufferModelView) * geoLocalNormal;
            texViewNormal = normalize(texViewNormal*1.02 - geoViewNormal);

            vec3 refractViewDir = refract(vec3(0.0, 0.0, 1.0), texViewNormal, eta);
            refractViewDir = normalize(refractViewDir);

            float depthNearL = linearizeDepth(depthTranslucent * 2.0 - 1.0, nearPlane, farPlane);
            float depthFarL = linearizeDepth(depthOpaque * 2.0 - 1.0, nearPlane, farPlane);
            float depthL = 0.06 * (depthFarL - depthNearL);

            vec2 refract_uv = refractViewDir.xy * depthL;
            refract_uv /= max(length(refract_uv), 1.0);

            coord += refract_uv * 0.02 * vec2(viewWidth / viewHeight, 1.0);
        }

        vec3 src = texture(TEX_FINAL, coord).rgb;
    #else
        vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    #endif

    uint matID = uint(tintData.a * 255.0 + 0.5);
//    vec3 tintColor = tintData.rgb;

    if (matID == MAT_STAINED_GLASS)
        src *= normalize(RGBToLinear(tintData.rgb));

    vec3 transNdcPos = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;
    vec3 transViewPos = project(gbufferProjectionInverse, transNdcPos);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        if (matID == MAT_WATER && isEyeInWater != 1 && depthTranslucent < depthOpaque) {
            vec3 opaqueNdcPos = vec3(texcoord, depthOpaque) * 2.0 - 1.0;
            vec3 opaqueViewPos = project(gbufferProjectionInverse, opaqueNdcPos);

            //        vec3 transNdcPos = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;
            //        vec3 transViewPos = project(gbufferProjectionInverse, transNdcPos);

            float waterDepth = distance(opaqueViewPos, transViewPos);

            // fog
            float borderFogF = GetBorderFogStrength(waterDepth);
            float envFogF = GetEnvFogStrength(waterDepth, true);
            float fogF = max(borderFogF, envFogF);

            vec3 fogColorL = RGBToLinear(fogColor);
//            vec3 skyColorL = RGBToLinear(skyColor);
            vec3 fogColorFinal = GetWaterFogColor(fogColorL, sunLocalDir, weatherStrength, skyDayF);

            src = mix(src, fogColorFinal, fogF);


            // absorption
    //        waterDepth = min(waterDepth, 8.0);
            vec3 waterAbsorbColorL = 1.0 - normalize(RGBToLinear(tintData.rgb));
    //        src *= exp(-3.0 * waterDepth * (1.0 - normalize(waterColor)));
            src *= GetWaterAbsorption(waterDepth, waterAbsorbColorL);
        }
    #endif

//    color.rgb = mix(src, color.rgb, color.a);
    color.rgb += src * (1.0 - color.a);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        if (isEyeInWater == 1) {
            float waterDepth = length(transViewPos);

//            waterDepth = min(waterDepth, 8.0);
            vec3 waterAbsorbColorL = 1.0 - normalize(RGBToLinear(fogColor));
//            color.rgb *= exp(-3.0 * waterDepth * (1.0 - normalize(waterColor)));
            color.rgb *= GetWaterAbsorption(waterDepth, waterAbsorbColorL);
        }
    #endif

    outFinal = color.rgb;
}
