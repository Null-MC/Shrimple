#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_TRANSLUCENT_FINAL;
uniform sampler2D TEX_GB_COLOR;
uniform usampler2D TEX_GB_SPECULAR;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#ifdef DISTANT_HORIZONS
    uniform sampler2D dhDepthTex0;
    uniform sampler2D dhDepthTex1;
#endif

#ifdef VOXY
    uniform sampler2D vxDepthTexOpaque;
    uniform sampler2D vxDepthTexTrans;
#endif

#ifdef REFRACT_ENABLED
//    uniform sampler2D depthtex0;
//    uniform sampler2D depthtex1;
    uniform sampler2D TEX_GB_NORMALS;
#endif

uniform float far;
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
uniform int hasSkylight;

uniform float dhFarPlane;
uniform mat4 dhProjectionInverse;
uniform mat4 vxProjInv;
uniform int vxRenderDistance;

#include "/lib/oklab.glsl"
#include "/lib/water-absorb.glsl"
#include "/lib/fog.glsl"

#ifdef REFRACT_ENABLED
    #include "/lib/sampling/depth.glsl"
    #include "/lib/octohedral.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 outFinal;

void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec4 color = texelFetch(TEX_TRANSLUCENT_FINAL, uv, 0);
    float depthOpaque = texelFetch(depthtex1, uv, 0).r;
    float depthTranslucent = texelFetch(depthtex0, uv, 0).r;

//    #if defined(MATERIAL_GLASS_TINT) || defined(WATER_FOG_FIX)
        vec4 tintColor = texelFetch(TEX_GB_COLOR, uv, 0);
//    #endif

    vec4 meta = unpackUnorm4x8(texelFetch(TEX_GB_SPECULAR, uv, 0).g);


    #ifdef REFRACT_ENABLED
//        float depthOpaque = texelFetch(depthtex1, uv, 0).r;
//        float depthTranslucent = texelFetch(depthtex0, uv, 0).r;
        vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);

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

    #ifdef DISTANT_HORIZONS
        bool isTransLod = depthTranslucent == 1.0;
        if (isTransLod) {
            depthTranslucent = texelFetch(dhDepthTex0, uv, 0).r;
        }
        vec3 transNdcPos = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;
        vec3 transViewPos = project(isTransLod ? dhProjectionInverse : gbufferProjectionInverse, transNdcPos);
    #elif defined(VOXY)
        bool isTransLod = depthTranslucent == 1.0;
        if (isTransLod) {
            depthTranslucent = texelFetch(vxDepthTexTrans, uv, 0).r;
        }
        vec3 transNdcPos = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;
        vec3 transViewPos = project(isTransLod ? vxProjInv : gbufferProjectionInverse, transNdcPos);
    #else
        vec3 transNdcPos = vec3(texcoord, depthTranslucent) * 2.0 - 1.0;
        vec3 transViewPos = project(gbufferProjectionInverse, transNdcPos);
    #endif

    #if defined(MATERIAL_GLASS_TINT) || defined(WATER_ABSORPTION) || defined(WATER_FOG_FIX)
        uint matID = uint(meta.a * 255.0 + 0.5);

        #ifdef MATERIAL_GLASS_TINT
            if (matID == MAT_STAINED_GLASS)
                src *= normalize(RGBToLinear(tintColor.rgb));
        #endif

        #if defined(WATER_FOG_FIX) || defined(WATER_ABSORPTION)
            #ifdef DISTANT_HORIZONS
                bool isOpaqueLod = depthOpaque == 1.0;
                if (isOpaqueLod) {
                    depthOpaque = texelFetch(dhDepthTex1, uv, 0).r;
                }
            #elif defined(VOXY)
                bool isOpaqueLod = depthOpaque == 1.0;
                if (isOpaqueLod) {
                    depthOpaque = texelFetch(vxDepthTexOpaque, uv, 0).r;
                }
            #endif

            vec3 opaqueNdcPos = vec3(texcoord, depthOpaque) * 2.0 - 1.0;

            #ifdef DISTANT_HORIZONS
                vec3 opaqueViewPos = project(isOpaqueLod ? dhProjectionInverse : gbufferProjectionInverse, opaqueNdcPos);
            #elif defined(VOXY)
                vec3 opaqueViewPos = project(isOpaqueLod ? vxProjInv : gbufferProjectionInverse, opaqueNdcPos);
            #else
                vec3 opaqueViewPos = project(gbufferProjectionInverse, opaqueNdcPos);
            #endif

            if (matID == MAT_WATER && isEyeInWater != 1 && transViewPos.z > opaqueViewPos.z) {
                float waterDepth = distance(opaqueViewPos, transViewPos);
                vec3 fogColorL = RGBToLinear(tintColor.rgb);

                #ifdef WATER_ABSORPTION
                    vec3 waterAbsorbColorL = 1.0 - normalize(fogColorL);
                    src *= GetWaterAbsorption(waterDepth, waterAbsorbColorL);
                #endif

                #ifdef WATER_FOG_FIX
                    float borderFogF = GetBorderFogStrength(waterDepth);
                    float envFogF = GetEnvFogStrength(waterDepth, true);

                    vec3 fogColorFinal = GetWaterFogColor(fogColorL, sunLocalDir, weatherStrength, skyDayF);

                    src = mix(src, fogColorFinal, max(borderFogF, envFogF));
                #endif
            }
        #endif
    #endif

//    color.rgb = mix(src, color.rgb, color.a);
    color.rgb += src * saturate(1.0 - color.a);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WATER_FOG_FIX)
        if (isEyeInWater == 1) {
            float waterDepth = length(transViewPos);

            #ifdef WATER_ABSORPTION
                vec3 waterAbsorbColorL = 1.0 - normalize(RGBToLinear(fogColor));
                color.rgb *= GetWaterAbsorption(waterDepth, waterAbsorbColorL);
            #endif

            #ifdef WATER_FOG_FIX
                // sky fog fix
                if (depthTranslucent == 1.0) {
                    float borderFogF = GetBorderFogStrength(waterDepth);
                    float envFogF = GetEnvFogStrength(waterDepth, true);

                    vec3 fogColorL = RGBToLinear(tintColor.rgb);
                    vec3 fogColorFinal = GetWaterFogColor(fogColorL, sunLocalDir, weatherStrength, skyDayF);

                    color.rgb = mix(color.rgb, fogColorFinal, max(borderFogF, envFogF));
                }
            #endif
        }
    #endif

    outFinal = color.rgb;
}
