#include "/lib/constants.glsl"
#include "/lib/common.glsl"


#include "/lib/blocks.glsl"
#include "/lib/sampling/lightmap.glsl"
#include "/lib/octohedral.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
//    #include "/lib/fresnel.glsl"
    #include "/lib/material/pbr.glsl"
#endif


#include "_outputDefer.glsl"

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    #if RENDER_SCALE != 0
        ivec2 uv = ivec2(gl_FragCoord.xy);
        if (any(greaterThan(uv, viewSizeScaled))) discard;
    #endif

    vec4 color = parameters.sampledColour;
    color.rgb *= parameters.tinting.rgb;

    vec3 ndcPos = gl_FragCoord.xyz;
    ndcPos.xy /= viewSizeScaled;
    ndcPos = ndcPos * 2.0 - 1.0;

    vec3 viewPos = project(vxProjInv, ndcPos);
    vec3 localPos = mul3(vxModelViewInv, viewPos);

    vec3 localNormal = vec3(
        uint((parameters.face >> 1) == 2),
        uint((parameters.face >> 1) == 0),
        uint((parameters.face >> 1) == 1)
    ) * (float(int(parameters.face) & 1) * 2.0 - 1.0);

    // TODO: if vanilla lighting, make foliage have "up" normals
    #ifndef MATERIAL_PBR_ENABLED
        bool isGrass = parameters.customId == BLOCK_GRASS_SHORT
            || parameters.customId == BLOCK_TALL_GRASS_LOWER
            || parameters.customId == BLOCK_TALL_GRASS_UPPER;

        if (isGrass) localNormal = vec3(0,1,0);
    #endif

//    vec3 albedo = RGBToLinear(color.rgb);
    vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

    vec3 localTexNormal = localNormal;
    #ifdef RENDER_TRANSLUCENT
        if (parameters.customId == BLOCK_WATER) {
            #ifndef WATER_TEXTURE_ENABLED
                color.rgb = vec3(0.0);//RGBToLinear(parameters.tinting.rgb);
                color.a = Water_f0;
            #endif

            #if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
                specularData = vec4(0.98, Water_f0, 0.0, 0.0);
            #endif

//            #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TRANSLUCENT)
//                vec2 waterWorldPos = (localPos.xz + cameraPosition.xz);
//                float waveHeight = wave_fbm(waterWorldPos, 12);
//                vec3 wavePos = vec3(localPos.xz, waveHeight);
//    //            wavePos.z += localPos.y - vIn.waveHeight;
//
//                vec3 dX = dFdx(wavePos);
//                vec3 dY = dFdy(wavePos);
//                localTexNormal = normalize(cross(normalize(dY), normalize(dX))).xzy;
//            #endif
        }
    #endif

    float viewDist = length(localPos);
    vec2 lmcoord = LightMapNorm(parameters.lightMap);
    const float occlusion = 1.0;


    outAlbedo = color;

    vec3 viewNormal = mat3(gbufferModelView) * localTexNormal;
    outNormals = vec4(OctEncode(localNormal), OctEncode(viewNormal));

    outSpecularMeta = uvec2(
        packUnorm4x8(specularData),
        packUnorm4x8(vec4(lmcoord, occlusion, 0.0))
    );

    #ifdef VELOCITY_ENABLED
        outVelocity = vec3(0.0);
    #endif
}
