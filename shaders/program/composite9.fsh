#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#ifdef LOD_ENABLED
    #define MAT_PROJ_INV matProjInv
    #define TEX_DEPTH_OPAQUE texDepthLod_opaque
    #define TEX_DEPTH_TRANS texDepthLod_trans
#else
    #define MAT_PROJ_INV gbufferProjectionInverse
    #define TEX_DEPTH_OPAQUE depthtex1
    #define TEX_DEPTH_TRANS depthtex0
#endif

in vec2 v_texcoord;

uniform sampler2D TEX_FINAL;
uniform sampler2D TEX_DEPTH_OPAQUE;
uniform sampler2D TEX_DEPTH_TRANS;
uniform sampler2D TEX_TRANSLUCENT_FINAL;
uniform sampler2D TEX_GB_COLOR;
uniform usampler2D TEX_GB_SPECULAR;

#ifdef REFRACT_ENABLED
    uniform sampler2D TEX_GB_NORMALS;
#endif

uniform float far;
uniform float near;
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
    float depthOpaque = texelFetch(TEX_DEPTH_OPAQUE, uv, 0).r;
    float depthTranslucent = texelFetch(TEX_DEPTH_TRANS, uv, 0).r;

    #if defined(MATERIAL_GLASS_TINT) || defined(WATER_FOG_FIX) || defined(WATER_ABSORPTION)
        vec3 tintColor = texelFetch(TEX_GB_COLOR, uv, 0).rgb;
        tintColor = RGBToLinear(tintColor);
    #endif

    vec4 meta = unpackUnorm4x8(texelFetch(TEX_GB_SPECULAR, uv, 0).g);


    #ifdef REFRACT_ENABLED
        vec4 normalData = texelFetch(TEX_GB_NORMALS, uv, 0);

        #ifdef LOD_ENABLED
            bool hasTrans = depthTranslucent > depthOpaque;
        #else
            bool hasTrans = depthTranslucent < depthOpaque;
        #endif

        vec2 coord = v_texcoord;
        if (hasTrans) {
            const float eta = (1.0 / 1.33);
            vec3 geoLocalNormal = OctDecode(normalData.xy);
            vec3 texViewNormal = OctDecode(normalData.zw);

            if (all(greaterThan(normalData.xy, vec2(0.0)))) {
            vec3 geoViewNormal = mat3(gbufferModelView) * geoLocalNormal;
            texViewNormal = normalize(texViewNormal*1.02 - geoViewNormal);

            vec3 refractViewDir = refract(vec3(0.0, 0.0, 1.0), texViewNormal, eta);
            refractViewDir = normalize(refractViewDir);

            #ifdef LOD_ENABLED
                float depthNearL = near / depthTranslucent;
                float depthFarL = near / depthOpaque;
            #else
                float depthNearL = linearizeDepth(depthTranslucent * 2.0 - 1.0, nearPlane, farPlane);
                float depthFarL = linearizeDepth(depthOpaque * 2.0 - 1.0, nearPlane, farPlane);
            #endif

            float depthL = 0.06 * (depthFarL - depthNearL);

            vec2 refract_uv = refractViewDir.xy * depthL;
            refract_uv /= max(length(refract_uv), 1.0);

            coord += refract_uv * 0.02 * vec2(viewWidth / viewHeight, 1.0);
            }
        }

        vec3 src = texture(TEX_FINAL, coord).rgb;
    #else
        vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    #endif

    #ifdef LOD_ENABLED
        mat4 matProjInv = mat4(
            gbufferProjectionInverse[0][0], 0.0, 0.0, 0.0,
            0.0, gbufferProjectionInverse[1][1], 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0/near,
            0.0, 0.0, -1.0, 0.0);
    #endif

    vec3 transNdcPos = screenToNdc(vec3(v_texcoord, depthTranslucent));
    vec3 transViewPos = project(MAT_PROJ_INV, transNdcPos);

    #if defined(MATERIAL_GLASS_TINT) || defined(WATER_ABSORPTION) || defined(WATER_FOG_FIX)
        uint matID = uint(meta.a * 255.0 + 0.5);

        #ifdef MATERIAL_GLASS_TINT
            if (matID == MAT_STAINED_GLASS)
                src *= normalize(tintColor);
        #endif

        #if defined(WATER_FOG_FIX) || defined(WATER_ABSORPTION)
            vec3 opaqueNdcPos = screenToNdc(vec3(v_texcoord, depthOpaque));
            vec3 opaqueViewPos = project(MAT_PROJ_INV, opaqueNdcPos);

            if (matID == MAT_WATER && isEyeInWater != 1 && transViewPos.z > opaqueViewPos.z) {
                float waterDepth = distance(opaqueViewPos, transViewPos);

                #ifdef WATER_ABSORPTION
                    vec3 waterAbsorbColorL = 1.0 - normalize(tintColor);
                    src *= GetWaterAbsorption(waterDepth, waterAbsorbColorL);
                #endif

                #ifdef WATER_FOG_FIX
                    float borderFogF = GetBorderFogStrength(waterDepth);
                    float envFogF = GetEnvFogStrength(waterDepth, true);

                    vec3 fogColorFinal = GetWaterFogColor(tintColor, sunLocalDir, weatherStrength, skyDayF);

                    src = mix(src, fogColorFinal, max(borderFogF, envFogF));
                #endif
            }
        #endif
    #endif

//    color.rgb = mix(src, color.rgb, color.a);
    color.rgb += src * saturate(1.0 - color.a);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && (defined(WATER_FOG_FIX) || defined(WATER_ABSORPTION))
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

                    vec3 fogColorFinal = GetWaterFogColor(tintColor, sunLocalDir, weatherStrength, skyDayF);

                    color.rgb = mix(color.rgb, fogColorFinal, max(borderFogF, envFogF));
                }
            #endif
        }
    #endif

    outFinal = color.rgb;
}
