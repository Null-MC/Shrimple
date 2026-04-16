#define RENDER_FRAGMENT

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;

    #ifdef RENDER_TERRAIN
        flat int blockId;

        #ifdef VELOCITY_ENABLED
            vec3 velocity;
        #endif

        #ifdef IRIS_FEATURE_FADE_VARIABLE
            flat float chunkFade;
        #endif
    #endif

    #ifdef RENDER_ENTITY
        vec3 localNormal;
    #else
        flat uint localNormal;
    #endif

    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
        float waveHeight;
    #endif

    #if defined(MATERIAL_PBR_ENABLED) || defined(WATER_WAVE_ENABLED)
        flat uint localTangent;
        flat float localTangentW;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        vec3 tangentViewPos;
        flat uint atlasTilePos;
        flat uint atlasTileSize;
        flat uint wrapMask;
    #endif
} vIn;


uniform sampler2D gtexture;

#ifdef MATERIAL_PBR_ENABLED
    uniform sampler2D normals;
    uniform sampler2D specular;
#endif

uniform float far;
uniform vec4 entityColor;
uniform int entityId;
uniform float alphaTestRef;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform ivec2 atlasSize;
uniform vec2 viewSize;

uniform int vxRenderDistance;
uniform float dhFarPlane;

#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/tbn.glsl"
#include "/lib/ign.glsl"
#include "/lib/hash-noise.glsl"
#include "/lib/octohedral.glsl"

#if defined(MATERIAL_PBR_ENABLED) || defined(LIGHTING_SPECULAR)
    #include "/lib/material/pbr.glsl"
#endif

#ifdef MATERIAL_PARALLAX_ENABLED
    #include "/lib/sampling/atlas.glsl"
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif

#if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
    #include "/lib/water-waves.glsl"
#endif


#include "_outputDefer.glsl"

void main() {
    float viewDist = length(vIn.localPos);

    vec2 texcoord = vIn.texcoord;
	float mip = textureQueryLod(gtexture, texcoord).y;
    vec3 localViewDir = vIn.localPos / viewDist;

    #ifdef RENDER_ENTITY
        vec3 localGeoNormal = normalize(vIn.localNormal);
    #else
        vec3 localGeoNormal = OctDecode(unpackUnorm2x16(vIn.localNormal));
    #endif

    #ifdef RENDER_TERRAIN
        int blockId = vIn.blockId;
    #endif

    #ifdef MATERIAL_PARALLAX_ENABLED
        bool skipParallax = false;

        #ifdef RENDER_TERRAIN
            if (blockId == BLOCK_LAVA || blockId == BLOCK_WATER || blockId == BLOCK_END_PORTAL) skipParallax = true;
        #elif defined(RENDER_ENTITY)
            if (entityId == ENTITY_SHADOW) skipParallax = true;
        #endif

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(vIn.tangentViewPos);

        ParallaxBounds bounds;
        if (!skipParallax && viewDist < MATERIAL_PARALLAX_MAX_DIST) {
            bounds.atlasTilePos = unpackUnorm2x16(vIn.atlasTilePos);
            bounds.atlasTileSize = unpackUnorm2x16(vIn.atlasTileSize);
            bounds.tanViewDir = tanViewDir;
            bounds.mip = mip;

            texcoord = GetParallaxCoord(bounds, texcoord, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureLod(gtexture, texcoord, mip);
    vec2 lmcoord = vIn.lmcoord;

    #ifdef RENDER_COLORWHEEL
        float ao;
        vec4 overlayColor;
        clrwl_computeFragment(color, color, lmcoord, ao, overlayColor);
        color.rgb = mix(color.rgb, overlayColor.rgb, overlayColor.a);
    #else
        #ifndef RENDER_SOLID
            if (color.a < alphaTestRef) discard;
        #endif
    #endif

    #ifdef RENDER_TERRAIN
        color.rgb *= vIn.color.rgb;
        float occlusion = vIn.color.a;
    #else
        float occlusion = 1.0;
        color *= vIn.color;
    #endif

    #ifdef RENDER_ENTITY
        color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

        if (entityId == BLOCK_PHYMOD_SNOW) {
            vec3 pixelPos = floor((vIn.localPos + cameraPosition) * 16.0) / 16.0;
            float noise = hash33(pixelPos).x;
            color.rgb *= noise * 0.06 + 0.94;
        }
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 normalData = textureLod(normals, texcoord, mip);
        vec3 tex_normal = mat_normal(normalData.xyz);
        occlusion *= mat_occlusion(normalData.a);

        #if defined(MATERIAL_PARALLAX_ENABLED) && MATERIAL_PARALLAX_TYPE == PARALLAX_SHARP
            float depthDiff = max(texDepth - traceCoordDepth.z, 0.0);

            if (depthDiff >= ParallaxSharpThreshold) {
                tex_normal = GetParallaxSlopeNormal(bounds, texcoord, traceCoordDepth.z);
            }
        #endif
    #else
        vec3 tex_normal = vec3(0.0, 0.0, 1.0);
    #endif

    #if defined(MATERIAL_PBR_ENABLED) || (defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT))
        vec3 localTangent = OctDecode(unpackUnorm2x16(vIn.localTangent));
        mat3 matLocalTBN = BuildTBN(localGeoNormal, localTangent, vIn.localTangentW);
        vec3 localTexNormal = normalize(matLocalTBN * tex_normal);
    #else
        vec3 localTexNormal = localGeoNormal;
    #endif

    #if defined(WATER_WAVE_ENABLED) && defined(RENDER_TERRAIN) && defined(RENDER_TRANSLUCENT)
        if (blockId == BLOCK_WATER) {
            vec2 waterWorldPos = (vIn.localPos.xz + cameraPosition.xz);
            float waveHeight = wave_fbm(waterWorldPos / WaterNormalScale, 12);
            vec3 wavePos = vec3(vIn.localPos.xz, waveHeight);
            wavePos.z += vIn.localPos.y - vIn.waveHeight;

            vec3 dX = dFdx(wavePos);
            vec3 dY = dFdy(wavePos);
            localTexNormal = normalize(cross(normalize(dY), normalize(dX))).xzy;// * sign(localGeoNormal.y);
        }
    #endif

    #ifdef DISTANT_HORIZONS
        if (viewDist > dh_clipDistF * far) {discard;}
    #endif

    #ifdef MATERIAL_PBR_ENABLED
        vec4 specularData = textureLod(specular, texcoord, mip);
    #else
        vec4 specularData = vec4(0.0, 0.04, 0.0, 0.0);

        // TODO: if vanilla lighting, make foliage have "up" normals
//        #if LIGHTING_MODE == LIGHTING_MODE_VANILLA
        #ifdef RENDER_TERRAIN
            bool isGrass = blockId == BLOCK_GRASS_SHORT
                || blockId == BLOCK_TALL_GRASS_LOWER
                || blockId == BLOCK_TALL_GRASS_UPPER;

            if (isGrass) localTexNormal = vec3(0,1,0);
        #endif
    #endif

    #ifdef RENDER_TERRAIN
        if (blockId == BLOCK_WATER) {
            #ifndef WATER_TEXTURE_ENABLED
                color.rgb = vec3(0.0);//RGBToLinear(vIn.color.rgb);
                color.a = Water_f0;
            #endif

            specularData = vec4(0.98, Water_f0, 0.0, 0.0);
        }
    #endif


    uint matId = 0u;
    #ifdef RENDER_HAND
        matId = MAT_HAND;
    #endif


    outAlbedo = color;

    vec3 viewTexNormal = mat3(gbufferModelView) * localTexNormal;
    outNormals = vec4(OctEncode(localGeoNormal), OctEncode(viewTexNormal));

    outSpecularMeta = uvec2(
        packUnorm4x8(specularData),
        packUnorm4x8(vec4(lmcoord, occlusion, matId / 255.0))
    );

    #ifdef VELOCITY_ENABLED
        #ifdef RENDER_TERRAIN
            outVelocity = vIn.velocity;
        #else
            outVelocity = vec3(0.0);
        #endif
    #endif
}
