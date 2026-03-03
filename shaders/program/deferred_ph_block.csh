#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#define TEX_DEPTH depthtex0

#ifndef PH_LIGHT_OFFSET
    #error "PH_LIGHT_OFFSET is undefined!"
#endif

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const vec2 workGroupsRender = vec2(1.0, 1.0);


shared int sharedLightList[256];
shared uint depthMinInt, depthMaxInt;
shared uint counter;

layout(rgba16f) uniform image2D IMG_FINAL;

#ifdef PHOTONICS_LIGHT_DEBUG
    layout(r16ui) uniform uimage2D imgLightDebug;
#endif

uniform sampler2D TEX_DEPTH;
uniform sampler2D TEX_FINAL;
uniform usampler2D TEX_TEX_NORMAL;
uniform usampler2D TEX_GEO_NORMAL;
uniform usampler2D TEX_REFLECT_SPECULAR;
uniform sampler2D texBlockLight;

uniform float near;
uniform float farPlane;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform int frameCounter;
uniform vec2 viewSize;
uniform float aspectRatio;
uniform vec2 taa_offset = vec2(0.0);

#include "/photonics/photonics.glsl"

#include "/lib/blocks.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/octohedral.glsl"
#include "/lib/fresnel.glsl"
#include "/lib/material.glsl"


vec3 unprojectCorner(const in float screenPosX, const in float screenPosY) {
    vec3 ndcPos = vec3(screenPosX, screenPosY, 1.0) * 2.0 - 1.0;
    return project(gbufferProjectionInverse, ndcPos);
}

float getLightRange(const in vec3 color, const in vec2 attenuation) {
    const float falloff = 1.0;
    float lum = luminance(color);
    return sqrt((((lum / 0.001) - 0.9) / attenuation.y) / falloff);
}


void main() {
    if (gl_LocalInvocationIndex == 0) {
        depthMinInt = UINT_MAX;
        depthMaxInt = 0u;
        counter = 0u;
    }

//    GroupMemoryBarrierWithGroupSync();
    barrier();

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    bool on_screen = all(lessThan(uv, viewSize));
    float depth;

    if (on_screen) {
        depth = texelFetch(TEX_DEPTH, uv, 0).r;

        if (depth < 1.0) {
            float depthL = linearizeDepth(depth * 2.0 - 1.0, near, farPlane);
            float depthInt = depthL / farPlane * UINT_MAX;
            atomicMin(depthMinInt, uint(floor(depthInt)));
            atomicMax(depthMaxInt, uint(ceil(depthInt)));
        }
    }

//    GroupMemoryBarrierWithGroupSync();
    barrier();

    float depthMin = depthMinInt / float(UINT_MAX) * farPlane;
    float depthMax = depthMaxInt / float(UINT_MAX) * farPlane;

    int lightIndex = PH_LIGHT_OFFSET + int(gl_LocalInvocationIndex);
    if (lightIndex < PH_MAX_LIGHTS) {
        Light light = load_light(lightIndex);
//        float lightRange = getLightRange(light.color, light.attenuation);
        ivec2 blockLightUV = ivec2(light.blockId % 256, light.blockId / 256);
        vec4 lightColorRange = texelFetch(texBlockLight, blockLightUV, 0);
//        vec3 ightColor = RGBToLinear(lightColorRange.rgb);
        float lightRange = lightColorRange.a * 32.0;

        if (lightRange > EPSILON && !(light.blockId == BLOCK_LAVA || light.blockId == BLOCK_CAVEVINE_BERRIES)) {
            // compute view-space position and collision test
            vec3 lightLocalPos = light.position - rt_camera_position;
            vec3 lightViewPos = mul3(gbufferModelView, lightLocalPos);
            bool hit = true;

            if (-lightViewPos.z + lightRange < depthMin) hit = false;
            if (-lightViewPos.z - lightRange > depthMax) hit = false;



//            vec3 lightClipPos = project(gbufferProjection, lightViewPos);
//            vec2 lightScreenPos = lightClipPos.xy * 0.5 + 0.5;
//
//            uvec2 groupPos = gl_WorkGroupID.xy * 16u;
//            vec2 screenMin = groupPos / viewSize;
//            vec2 screenMax = (groupPos + 16u) / viewSize;
//            vec2 nearest = clamp(lightScreenPos, screenMin, screenMax);
//
//            float f = 0.75 * gbufferProjection[1][1];
//            float screenRadius = f * (lightRange + 0.5) / -lightViewPos.z;
//
//            float lightDistSq = lengthSq((nearest - lightScreenPos) * vec2(aspectRatio, 1.0));
//            if (lightDistSq > _pow2(screenRadius)) hit = false;


            // test X/Y
            uvec2 groupPos = gl_WorkGroupID.xy * 16u;
            vec2 groupPosMin = groupPos / viewSize;
            vec2 groupPosMax = (groupPos + 16u) / viewSize;

            vec3 c1 = unprojectCorner(groupPosMin.x, groupPosMin.y);
            vec3 c2 = unprojectCorner(groupPosMax.x, groupPosMin.y);
            vec3 c3 = unprojectCorner(groupPosMin.x, groupPosMax.y);
            vec3 c4 = unprojectCorner(groupPosMax.x, groupPosMax.y);

            vec3 clipDown  = normalize(cross(c2, c1));
            vec3 clipRight = normalize(cross(c4, c2));
            vec3 clipUp    = normalize(cross(c3, c4));
            vec3 clipLeft  = normalize(cross(c1, c3));

            if (dot(clipDown,  lightViewPos) > lightRange) hit = false;
            if (dot(clipRight, lightViewPos) > lightRange) hit = false;
            if (dot(clipUp,    lightViewPos) > lightRange) hit = false;
            if (dot(clipLeft,  lightViewPos) > lightRange) hit = false;

            if (hit) {
                uint index = atomicAdd(counter, 1u);
                sharedLightList[index] = lightIndex;
            }
        }
    }

//    GroupMemoryBarrierWithGroupSync();
    barrier();

    if (!on_screen) return;

    vec3 lighting = vec3(0.0);

    if (depth < 1.0) { // && counter > 0
        vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / viewSize;

        #ifdef TAA_ENABLED
            texcoord -= taa_offset;
        #endif

        vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;

        // TODO: fix hand depth

        vec3 viewPos = project(gbufferProjectionInverse, ndcPos);
        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        uint reflectNormalData = texelFetch(TEX_TEX_NORMAL, uv, 0).r;
        vec3 viewTexNormal = OctDecode(unpackUnorm2x16(reflectNormalData));
        vec3 localTexNormal = mat3(gbufferModelViewInverse) * viewTexNormal;

        uint geoNormalData = texelFetch(TEX_GEO_NORMAL, uv, 0).r;
        vec3 localGeoNormal = OctDecode(unpackUnorm2x16(geoNormalData));


        #if defined(PHOTONICS_LIGHT_DEBUG) && PH_LIGHT_OFFSET == 0
            ivec2 group_uv = ivec2(gl_WorkGroupID.xy);
            uvec4 data = imageLoad(imgLightDebug, group_uv);
            data.r += counter;
            imageStore(imgLightDebug, group_uv, data);
//            imageAtomicAdd(imgLightDebug, group_uv, uvec4(counter));
        #endif


        counter = min(counter, PH_MAX_LIGHTS);
        for (uint i = 0; i < counter; i++) {
            int lightIndex = sharedLightList[i];
            Light light = load_light(lightIndex);

            vec3 lightLocalPos = light.position - rt_camera_position;
            vec3 lightOffset = lightLocalPos - localPos;
            float lightDist = length(lightOffset);
            vec3 lightDir = lightOffset / lightDist;

//            vec3 lightColor = 3.0 * light.color;
//            float lightRange = getLightRange(light.color, light.attenuation);
            ivec2 blockLightUV = ivec2(light.blockId % 256, light.blockId / 256);
            vec4 lightColorRange = texelFetch(texBlockLight, blockLightUV, 0);
            vec3 lightColor = RGBToLinear(lightColorRange.rgb);
            float lightRange = lightColorRange.a * 32.0;

            lightColor *= 6.0 * (lightRange / 15.0);

            float NoLm = max(dot(localTexNormal, lightDir), 0.0);

            float att_linear = 1.0 - saturate(lightDist / lightRange);
//            float att_sq = 1.0 / (1.0 + _pow2(lightDist));
//            float att = min(att_sq, _pow2(att_linear));
            float att = _pow3(att_linear);


//            vec3 rtOrigin = light.position - 0.5 * lightDir;
            vec3 rtOrigin = localPos + rt_camera_position
                + 0.02 * localGeoNormal;

            RayJob ray = RayJob(rtOrigin, lightDir,
                vec3(0), vec3(0), vec3(0), false);

            RAY_ITERATION_COUNT = PHOTONICS_LIGHT_STEPS;
            // breakOnEmpty=true;

            trace_ray(ray, true);

            if (ray.result_hit) {
                lightColor *= result_tint_color;

                if (lengthSq(rtOrigin - ray.result_position) < _pow2(lightDist) && floor(light.position) != floor(ray.result_position)) {
                    att = 0.0;
                }
            }

            lighting += NoLm * _pow2(att) * lightColor;
        }


        uvec2 reflectData = texelFetch(TEX_REFLECT_SPECULAR, uv, 0).rg;
        vec4 specularData = unpackUnorm4x8(reflectData.g);

        #ifdef MATERIAL_PBR_ENABLED
            float smoothness = 1.0 - mat_roughness(specularData.r);
            float metalness = mat_metalness(specularData.g);
            float f0 = mat_f0(specularData.g);

            lighting *= 1.0 - metalness * sqrt(smoothness);
        #else
            float smoothness = 1.0 - mat_roughness_lab(specularData.r);
            float f0 = mat_f0_lab(specularData.g);
        #endif

        vec3 localViewDir = normalize(localPos);
        float NoV = dot(localTexNormal, -localViewDir);
        lighting *= 1.0 - F_schlick(NoV, f0, 1.0) * _pow2(smoothness);


        vec4 reflectDataR = unpackUnorm4x8(reflectData.r);
        lighting *= RGBToLinear(reflectDataR.rgb);
    }

    vec3 src = texelFetch(TEX_FINAL, uv, 0).rgb;
    imageStore(IMG_FINAL, uv, vec4(src + lighting, 1.0));
}
