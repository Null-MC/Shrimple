#define RENDER_FRAGMENT
#define RENDER_TRANSLUCENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 localNormal;

    vec3 physics_localPosition;
    float physics_localWaviness;
} vIn;


uniform sampler2D gtexture;

#ifdef MATERIAL_PBR_ENABLED
    uniform sampler2D normals;
    uniform sampler2D specular;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFillA;
    uniform sampler3D texFloodFillB;

    #if defined(LIGHTING_HAND) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        uniform sampler2D texBlockLight;
    #endif
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#ifdef SHADOWS_ENABLED
    uniform SHADOW_SAMPLER TEX_SHADOW;

    #ifdef SHADOW_COLORED
        uniform SHADOW_SAMPLER TEX_SHADOW_COLOR;
        uniform sampler2D shadowcolor0;
    #endif
#endif

#ifdef SHADOW_CLOUDS
    uniform sampler2D texCloudShadow;
#endif

uniform float far;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float skyDayF;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform vec3 sunLocalDir;
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform int isEyeInWater;
uniform int frameCounter;
uniform int heldItemId;
uniform int heldItemId2;

uniform int vxRenderDistance;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/hsv.glsl"
#include "/lib/ign.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/shadows.glsl"
#include "/lib/phy-ocean.glsl"

//#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
//    #include "/lib/fresnel.glsl"
//    #include "/lib/pbr.glsl"
//#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#else
    #include "/lib/vanilla-light.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

#if defined(LIGHTING_HAND) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
    #ifdef LIGHTING_COLORED
        #include "/lib/sampling/block-light.glsl"
    #endif

    #include "/lib/hand-light.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void main() {
    float viewDist = length(vIn.localPos);

    #ifdef DISTANT_HORIZONS
        if (viewDist > dh_clipDistF * far) {
            discard;
            return;
        }
    #endif

    vec2 texcoord = vIn.texcoord;
    float mip = textureQueryLod(gtexture, texcoord).y;
    vec3 localViewDir = vIn.localPos / viewDist;

    vec4 color = textureLod(gtexture, texcoord, mip);
    color.rgb *= vIn.color.rgb;

//    #ifdef MATERIAL_PBR_ENABLED
////        vec4 normalData = textureLod(normals, texcoord, mip);
////        vec3 tex_normal = mat_normal(normalData.xyz);
////        float tex_occlusion = mat_occlusion(normalData.w);
//
////        vec3 localTangent = OctDecode(unpackUnorm2x16(vIn.localTangent));
////        mat3 matLocalTBN = BuildTBN(localGeoNormal, localTangent, vIn.localTangentW);
////        vec3 localTexNormal = normalize(matLocalTBN * tex_normal);
//
//        vec4 specularData = textureLod(specular, texcoord, mip);
////        float sss = mat_sss(specularData.b);
//    #else
//        vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);
////        vec3 localTexNormal = localGeoNormal;
////        const float tex_occlusion = 1.0;
////        const float sss = 0.0;
//    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    #ifndef WATER_TEXTURE_ENABLED
        albedo = RGBToLinear(vIn.color.rgb);
        color.a = 0.04;
    #endif

//    #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)
        vec4 specularData = vec4(0.98, 0.02, 0.0, 0.0);
//    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if (defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_REFLECT_ENABLED)) && defined(RENDER_TERRAIN)
        // TODO: add option to make clear?
        //            albedo = vec3(0.0);
        specularData = vec4(0.98, 0.02, 0.0, 0.0);
    #endif

    float waviness = max(vIn.physics_localWaviness, 0.02);
    WavePixelData wave = physics_wavePixel(vIn.physics_localPosition.xz, waviness, physics_iterationsNormal, physics_gameTime);
    vec2 waterUvOffset = wave.worldPos - vIn.physics_localPosition.xz;
    vec3 localTexNormal = wave.normal.xzy;

    // TODO: foam looks weird with textured water
    color.a = mix(color.a, 1.0, wave.foam);
    albedo = mix(albedo, vec3(0.92), wave.foam);
    specularData.r = mix(specularData.r, 0.48, wave.foam);

    vec3 localGeoNormal = normalize(vIn.localNormal);
    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    vec3 shadow = vec3(1.0);
    #ifdef SHADOWS_ENABLED
//        vec3 localTexNormal = localGeoNormal; // TODO: temp

        vec3 shadowViewGeoNormal = mat3(shadowModelView) * localGeoNormal;

        vec3 shadowPos = vIn.localPos;
        shadowPos += 0.08 * localGeoNormal;
        shadowPos = mul3(shadowModelView, shadowPos);

//        #ifdef MATERIAL_PBR_ENABLED
//            shadowPos.z += sss;
//        #endif

        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        shadow = SampleShadows(shadowPos);

        float shadow_NoL = dot(localTexNormal, localSkyLightDir);

//        #ifdef MATERIAL_PBR_ENABLED
//            shadow_NoL = mix(shadow_NoL, 1.0, sss);
//        #endif

        shadow *= pow(saturate(shadow_NoL), 0.2);
    #endif

    #ifdef SHADOW_CLOUDS
        shadow *= SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    vec2 lmcoord = vIn.lmcoord;

    #ifdef PHOTONICS_BLOCK_LIGHT_ENABLED
        lmcoord.x = 0.0;
    #endif

    #ifndef PHOTONICS_HAND_LIGHT_ENABLED
        #ifdef LIGHTING_HAND
            vec3 handLightPos = GetHandLightPosition();
            float handDist = distance(vIn.localPos, handLightPos);
        #endif

        #if defined(LIGHTING_HAND) && !defined(LIGHTING_COLORED)
            float handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
            float handLight = max(handLightLevel - handDist, 0.0) / 15.0;

            lmcoord.x = max(lmcoord.x, handLight);
        #endif
    #endif

    #ifdef LIGHTING_COLORED
        vec3 voxelPos = GetVoxelPosition(vIn.localPos);
        float lpvFade = GetVoxelFade(voxelPos);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 blockLight = lmcoord.x * blockLightColor;

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos) * 3.0;
            blockLight = mix(blockLight, lpvSample, lpvFade);
        #endif

        vec3 skyLight = vec3(0.0);
        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);
            float skyLight_NoLm = max(dot(localSkyLightDir, localTexNormal), 0.0);

//            #ifdef MATERIAL_PBR_ENABLED
//                skyLight_NoLm = mix(skyLight_NoLm, 1.0, 0.7*sss);
//            #endif

            skyLight = skyLight_NoLm * shadow * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

//            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(localTexNormal);
//            #endif
        #endif

        color.rgb = albedo * (blockLight + skyLight + MinAmbientF);
    #else
        lmcoord.y = min(lmcoord.y, maxOf(shadow) * (1.0 - AmbientLightF) + AmbientLightF);

        float oldLighting = GetOldLighting(localTexNormal);
//        #ifdef MATERIAL_PBR_ENABLED
//            oldLighting = mix(oldLighting, 1.0, sss);
//        #endif
        lmcoord.y *= oldLighting;

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        lmcoord = LightMapTex(lmcoord);
        vec3 lit = texture(lightmap, lmcoord).rgb;
        lit = RGBToLinear(lit);

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, localTexNormal);
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            lit += lpvFade * lpvSample;
        #endif

        color.rgb = albedo * lit;
    #endif

    #if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED) && !defined(PHOTONICS_HAND_LIGHT_ENABLED)
        float handLight1 = max(heldBlockLightValue  - handDist, 0.0) / 15.0;
        float handLight2 = max(heldBlockLightValue2 - handDist, 0.0) / 15.0;

        vec3 handLightColor1 = vec3(1.0);
        if (heldItemId >= 0) {
            float lightRange;
            GetBlockColorRange(heldItemId, handLightColor1, lightRange);
        }

        vec3 handLightColor2 = vec3(1.0);
        if (heldItemId2 >= 0) {
            float lightRange;
            GetBlockColorRange(heldItemId2, handLightColor2, lightRange);
        }

        vec3 lightDir = normalize(vIn.localPos - handLightPos);
        float NoLm = max(dot(localTexNormal, -lightDir), 0.0);

        if (heldBlockLightValue > 0 || heldBlockLightValue2 > 0) {
            color.rgb += albedo * NoLm * (_pow2(handLight1) * handLightColor1 + _pow2(handLight2) * handLightColor2);
        }
    #endif

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

    color.rgb = mix(color.rgb, fogColorFinal, fogF);

    outFinal = color;
    outTint = vec3(1.0);

    #ifdef TAA_ENABLED
        // TODO: we could actually set this but useless for translucent rn
        outVelocity = vec3(0.0);
    #endif

    #ifdef DEFERRED_NORMAL_ENABLED
        vec3 viewTexNormal = mat3(gbufferModelView) * localTexNormal;

        outNormal = uvec2(
            packUnorm2x16(OctEncode(localGeoNormal)),
            packUnorm2x16(OctEncode(viewTexNormal)));
    #endif

    #ifdef DEFERRED_SPECULAR_ENABLED
        outAlbedoSpecular = uvec2(
            packUnorm4x8(vec4(LinearToRGB(albedo), vIn.lmcoord.y)),
            packUnorm4x8(specularData));
    #endif
}
