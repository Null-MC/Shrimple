#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    flat uint color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
} vIn;


uniform sampler2D gtexture;

#ifdef MATERIAL_PBR_ENABLED
    uniform sampler2D normals;
    uniform sampler2D specular;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED && defined(WORLD_OVERWORLD)
    uniform sampler2D texSkyTransmit;
    uniform sampler3D texSkyIrradiance;
#endif

#if LIGHTING_MODE == LIGHTING_MODE_VANILLA
    uniform sampler2D lightmap;
#endif

#ifdef LIGHTING_COLORED
    uniform sampler3D texFloodFill;

    #ifdef LIGHTING_HAND
        uniform sampler2D texBlockLight;
    #endif
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
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 skyColor;
uniform float cloudHeight;
uniform float cloudTime;
uniform vec3 eyePosition;
uniform float rainStrength;
uniform float weatherStrength;
uniform float weatherDensity;
uniform float alphaTestRef;
uniform float skyDayF;
uniform vec3 sunLocalDir;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform bool firstPersonCamera;
uniform vec3 relativeEyePosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int hasSkylight;
uniform int frameCounter;
uniform int isEyeInWater;

uniform int textureFilteringMode;
uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/oklab.glsl"
#include "/lib/fog.glsl"
#include "/lib/ign.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/shadows.glsl"

#ifdef MATERIAL_PBR_ENABLED
    #include "/lib/material/pbr.glsl"
#endif

#if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
    #ifdef WORLD_OVERWORLD
        #include "/lib/sky-transmit.glsl"
        #include "/lib/sky-irradiance.glsl"
    #endif

    #include "/lib/enhanced-lighting.glsl"
#endif

#ifdef LIGHTING_COLORED
    #include "/lib/voxel.glsl"
    #include "/lib/floodfill-render.glsl"
#endif

#ifdef LIGHTING_HAND
    #ifdef LIGHTING_COLORED
        #include "/lib/sampling/block-light.glsl"
    #endif

    #include "/lib/lighting/attenuation.glsl"
    #include "/lib/lighting/hand.glsl"
#endif

#ifdef SHADOWS_ENABLED
    #include "/lib/shadow-sample.glsl"
#endif

#ifdef SHADOW_CLOUDS
    #include "/lib/cloud-shadows.glsl"
#endif


#include "_output.glsl"

void main() {
    vec2 texcoord = vIn.texcoord;
    float mip = textureQueryLod(gtexture, texcoord).y;
    float viewDist = length(vIn.localPos);

    vec4 color = textureLod(gtexture, texcoord, mip);

    if (color.a < alphaTestRef) discard;

    vec4 tint = unpackUnorm4x8(vIn.color);
    #if defined(RENDER_TERRAIN) && LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        color.rgb *= tint.rgb;
    #else
        color *= tint;
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 normalData = textureLod(normals, texcoord, mip);
    //    vec3 tex_normal = mat_normal(normalData.xyz);
        float tex_occlusion = mat_occlusion(normalData.w);

        vec4 specularData = textureLod(specular, texcoord, mip);
    #else
        const float tex_occlusion = 1.0;
    #endif

    vec3 albedo = RGBToLinear(color.rgb);

    vec3 localSkyLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        vec3 shadow = vec3(1.0);
    #else
        float shadowF = 1.0;
    #endif

    float cloudShadowF = 1.0;
    #ifdef SHADOW_CLOUDS
        cloudShadowF = SampleCloudShadow(vIn.localPos, localSkyLightDir);
    #endif

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos = mul3(shadowModelView, vIn.localPos);
        shadowPos.z += 0.016 * viewDist;
        shadowPos = (shadowProjection * vec4(shadowPos, 1.0)).xyz;

        distort(shadowPos.xy);
        shadowPos = shadowPos * 0.5 + 0.5;

        #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
            shadow = SampleShadowColor(shadowPos);
            shadow *= cloudShadowF;
        #else
            shadowF = SampleShadows(shadowPos);
            shadowF *= cloudShadowF;
        #endif
    #endif

    #ifdef LIGHTING_COLORED
        vec3 voxelPos = GetVoxelPosition(vIn.localPos);
        float lpvFade = GetVoxelFade(voxelPos);
    #endif

    vec2 lmcoord = vIn.lmcoord;
    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        lmcoord = _pow3(lmcoord);

        const vec3 blockLightColor = pow(vec3(0.922, 0.871, 0.686), vec3(2.2));
        vec3 diffuseFinal = lmcoord.x * blockLightColor;

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, vec3(0.0));
            vec3 lpvSample = SampleFloodFill(samplePos);
//            blockLight = mix(blockLight, lpvSample, lpvFade);
            diffuseFinal += lpvSample * lpvFade;
        #endif

        #ifdef WORLD_OVERWORLD
            vec3 skyLightColor = GetSkyLightColor(vIn.localPos, sunLocalDir.y, localSkyLightDir.y);
            vec3 skyLight = shadow * skyLightColor;

            #ifndef SHADOWS_ENABLED
                skyLight *= lmcoord.y;
            #endif

            #ifndef PHOTONICS_GI_ENABLED
                skyLight += lmcoord.y * AmbientLightF * SampleSkyIrradiance(vec3(0,1,0));
            #endif

            diffuseFinal += skyLight;
        #endif
    #else
        lmcoord.y = min(lmcoord.y, shadowF * (1.0 - AmbientLightF) + AmbientLightF);

        #ifdef LIGHTING_COLORED
            lmcoord.x *= 1.0 - lpvFade;
        #endif

        lmcoord = LightMapTex(lmcoord);
        vec3 diffuseFinal = texture(lightmap, lmcoord).rgb;
        diffuseFinal = RGBToLinear(diffuseFinal);

        #ifdef LIGHTING_COLORED
            vec3 samplePos = GetFloodFillSamplePos(voxelPos, vec3(0.0));
            vec3 lpvSample = SampleFloodFill(samplePos, pow(vIn.lmcoord.x, 2.2));
            diffuseFinal += lpvFade * lpvSample;
        #endif
    #endif

    // TODO: move to ambient lighting?
    diffuseFinal *= tex_occlusion;

    #if defined(LIGHTING_HAND) && defined(LIGHTING_COLORED)
        vec3 handLightPos = GetHandLightPosition();
        float handDist = distance(vIn.localPos, handLightPos);

        if (heldItemId >= 0) {
            vec3 lightColor;
            float lightRange;
            GetBlockColorRange(heldItemId, lightColor, lightRange);

            const float lightRadius = 0.5;
            float att = GetLightAttenuation(handDist, lightRange, lightRadius);
            vec3 handLightDir = normalize(handLightPos - vIn.localPos);
//            float hand_NoLm = max(dot(localTexNormal, handLightDir), 0.0);

            diffuseFinal += att * lightColor;
//            #ifdef LIGHTING_SPECULAR
//                specularFinal += att * SampleLightSpecular(albedo, localTexNormal, handLightDir, -localViewDir, hand_NoLm, roughL, specularData.g) * lightColor;
//            #endif
        }

        if (heldItemId2 >= 0) {
            vec3 lightColor;
            float lightRange;
            GetBlockColorRange(heldItemId2, lightColor, lightRange);

            const float lightRadius = 0.5;
            float att = GetLightAttenuation(handDist, lightRange, lightRadius);
            vec3 handLightDir = normalize(handLightPos - vIn.localPos);
//            float hand_NoLm = max(dot(localTexNormal, handLightDir), 0.0);

            diffuseFinal += att * lightColor;
//            #ifdef LIGHTING_SPECULAR
//                specularFinal += att * SampleLightSpecular(albedo, localTexNormal, handLightDir, -localViewDir, hand_NoLm, roughL, specularData.g) * lightColor;
//            #endif
        }
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        float emission = mat_emission(specularData);
        TransformEmission(emission);
        diffuseFinal += emission;
    #endif

    #ifdef DEBUG_WHITEWORLD
        albedo = vec3(0.86);
    #endif

    #if LIGHTING_MODE == LIGHTING_MODE_ENHANCED
        outFinal.rgb = albedo/PI * diffuseFinal * color.a;// + specularFinal;
    #else
        outFinal.rgb = albedo * diffuseFinal * color.a;// + specularFinal;
    #endif
    outFinal.a = color.a;

    float borderFogF = GetBorderFogStrength(viewDist);
    float envFogF = GetEnvFogStrength(viewDist);
    float fogF = max(borderFogF, envFogF);

    vec3 fogColorL = RGBToLinear(fogColor);
    vec3 skyColorL = RGBToLinear(skyColor);
    vec3 localViewDir = normalize(vIn.localPos);
    vec3 fogColorFinal = GetSkyFogWaterColor(skyColorL, fogColorL, localViewDir);

    outFinal.rgb = mix(outFinal.rgb, fogColorFinal, fogF);

    #ifdef DEFERRED_ENABLED
        outAlbedo = color;

        outNormals = vec4(0.0);
        outSpecularMeta = uvec2(0u);
    #endif

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif
}
