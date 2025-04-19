#define RENDER_COMPOSITE_DIFFUSE_RT_FILTER
#define RENDER_COMPOSITE
#define RENDER_COMPUTE

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

const int sharedBufferRes = 20;
const int sharedBufferSize = _pow2(sharedBufferRes);

shared float gaussianBuffer[5];
shared vec3 sharedDiffuseBuffer[sharedBufferSize];
shared float sharedDepthBuffer[sharedBufferSize];

#if MATERIAL_SPECULAR != SPECULAR_NONE
    shared vec3 sharedSpecularBuffer[sharedBufferSize];
#endif

layout(rgba16f) uniform writeonly image2D imgDiffuseRT;
layout(rgba16f) uniform writeonly image2D imgDiffuseRT_alt;

uniform sampler2D texDiffuseRT;
uniform sampler2D texDiffuseRT_alt;

#if MATERIAL_SPECULAR != SPECULAR_NONE
    layout(rgba16f) uniform writeonly image2D imgSpecularRT;
    layout(rgba16f) uniform writeonly image2D imgSpecularRT_alt;

    uniform sampler2D texSpecularRT;
    uniform sampler2D texSpecularRT_alt;
#endif

layout(rgba16f) uniform writeonly image2D imgLocalPosLast;
layout(rgba16f) uniform writeonly image2D imgLocalPosLast_alt;

uniform sampler2D texLocalPosLast;
uniform sampler2D texLocalPosLast_alt;

uniform sampler2D BUFFER_BLOCK_DIFFUSE;
uniform sampler2D BUFFER_VELOCITY;
uniform sampler2D depthtex1;

#if MATERIAL_SPECULAR != SPECULAR_NONE
    uniform sampler2D BUFFER_BLOCK_SPECULAR;
#endif

#ifdef DISTANT_HORIZONS
	uniform sampler2D dhDepthTex1;
#endif

uniform vec2 viewSize;
uniform float near;
uniform float far;
uniform float farPlane;
uniform int frameCounter;

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;

// uniform bool hideGUI;

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#include "/lib/buffers/scene.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/catmull-rom.glsl"
#include "/lib/sampling/gaussian.glsl"


const float AccumMaxFrames = 60.0;
const float AccumMaxFrames_specular = 8.0;
const float g_sigmaXY = 220.0;
const float g_sigmaV = 0.1;

void populateSharedBuffer() {
    if (gl_LocalInvocationIndex < 5)
        gaussianBuffer[gl_LocalInvocationIndex] = Gaussian(g_sigmaXY, abs(gl_LocalInvocationIndex - 2));
    
    uint i_base = uint(gl_LocalInvocationIndex) * 2u;
    if (i_base >= sharedBufferSize) return;

    ivec2 uv_base = ivec2(gl_WorkGroupID.xy * gl_WorkGroupSize.xy) - 2;

    for (uint i = 0u; i < 2u; i++) {
	    uint i_shared = i_base + i;
	    if (i_shared >= sharedBufferSize) break;
	    
    	ivec2 uv_i = ivec2(
            i_shared % sharedBufferRes,
            i_shared / sharedBufferRes
        );

	    ivec2 uv = uv_base + uv_i;

	    float depthL = far;
	    vec3 diffuse = vec3(0.0);
        vec3 specular = vec3(0.0);

	    if (all(greaterThanEqual(uv, ivec2(0))) && all(lessThan(uv, ivec2(viewSize + 0.5)))) {
            vec2 sampleCoord = uv/viewSize;
	    	diffuse = textureLod(BUFFER_BLOCK_DIFFUSE, sampleCoord, 0).rgb;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                specular = textureLod(BUFFER_BLOCK_SPECULAR, sampleCoord, 0).rgb;
            #endif

	    	float depth = texelFetch(depthtex1, uv, 0).r;
	    	depthL = linearizeDepth(depth, near, farPlane);

            #ifdef DISTANT_HORIZONS
                float depthDH = texelFetch(dhDepthTex1, uv, 0).r;
                float depthDHL = linearizeDepth(depthDH, dhNearPlane, dhFarPlane);

                if (depth >= 1.0 || (depthDHL < depthL && depthDH > 0.0)) {
                    //depth = depthDH;
                    depthL = depthDHL;
                }
            #endif
	    }

    	sharedDiffuseBuffer[i_shared] = diffuse;
    	sharedDepthBuffer[i_shared] = depthL;

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            sharedSpecularBuffer[i_shared] = specular;
        #endif
    }
}

void sampleSharedBuffer(const in float depthL, out vec3 outDiffuse, out vec3 outSpecular) {
    ivec2 uv_base = ivec2(gl_LocalInvocationID.xy) + 2;

    vec3 accumDiffuse = vec3(0.0);
    vec3 accumSpecular = vec3(0.0);
    float total = 0.0;
    
    for (int iy = -2; iy <= 2; iy++) {
        float fy = gaussianBuffer[iy+2];

        for (int ix = -2; ix <= 2; ix++) {
            float fx = gaussianBuffer[ix+2];
            
            ivec2 uv_shared = uv_base + ivec2(ix, iy);
            int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;

            vec3 sampleDiffuse = sharedDiffuseBuffer[i_shared];
            float sampleDepthL = sharedDepthBuffer[i_shared];

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                vec3 sampleSpecular = sharedSpecularBuffer[i_shared];
            #endif
            
            float fv = Gaussian(g_sigmaV, sampleDepthL - depthL);
            
            float weight = fx*fy*fv;
            total += weight;

            accumDiffuse += weight * sampleDiffuse;

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                accumSpecular += weight * sampleSpecular;
            #endif
        }
    }
    
    if (total > EPSILON) {
        outDiffuse = accumDiffuse / total;
        outSpecular = accumSpecular / total;
    }
    else {
        outDiffuse = vec3(0.0);
        outSpecular = vec3(0.0);
    }
}


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    populateSharedBuffer();

    // memoryBarrierShared();
    // memoryBarrier();
    barrier();

	if (any(greaterThanEqual(uv, ivec2(viewSize)))) return;

    ivec2 uv_shared = ivec2(gl_LocalInvocationID.xy) + 2;
    int i_shared = uv_shared.y * sharedBufferRes + uv_shared.x;
	float depthL = sharedDepthBuffer[i_shared];

    #ifdef LIGHTING_TRACED_ACCUMULATE
        vec2 texcoord = (uv + 0.5) / viewSize;
        bool altFrame = (frameCounter % 2) == 0;

        vec3 velocity = textureLod(BUFFER_VELOCITY, texcoord, 0).xyz;

        #ifdef DISTANT_HORIZONS
            float depth = delinearizeDepth(depthL, near, dhFarPlane);
        #else
            float depth = delinearizeDepth(depthL, near, farPlane);
        #endif

        vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;

        #ifdef DISTANT_HORIZONS
            vec3 viewPos = unproject(dhProjectionFullInv, ndcPos);
        #else
            vec3 viewPos = unproject(gbufferProjectionInverse, ndcPos);
        #endif

        vec3 localPos = mul3(gbufferModelViewInverse, viewPos);

        vec3 localPos_re = localPos + (cameraPosition - previousCameraPosition) - velocity;

        vec3 viewPos_re = mul3(gbufferPreviousModelView, localPos_re);

        #ifdef DISTANT_HORIZONS
            vec3 ndcPos_re = unproject(dhProjectionFullPrev, viewPos_re);
        #else
            vec3 ndcPos_re = unproject(gbufferPreviousProjection, viewPos_re);
        #endif

        vec2 texcoord_re = ndcPos_re.xy * 0.5 + 0.5;


        vec3 diffuseOld, specularOld;

        #ifdef LIGHTING_TRACE_SHARPEN
            if (altFrame) {
                diffuseOld = sample_CatmullRom(texDiffuseRT, texcoord_re, viewSize).rgb;

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    specularOld = sample_CatmullRom(texSpecularRT, texcoord_re, viewSize).rgb;
                #endif
            }
            else {
                diffuseOld = sample_CatmullRom(texDiffuseRT_alt, texcoord_re, viewSize).rgb;

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    specularOld = sample_CatmullRom(texSpecularRT_alt, texcoord_re, viewSize).rgb;
                #endif
            }
        #else
            if (altFrame) {
                diffuseOld = textureLod(texDiffuseRT, texcoord_re, 0).rgb;

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    specularOld = textureLod(texSpecularRT, texcoord_re, 0).rgb;
                #endif
            }
            else {
                diffuseOld = textureLod(texDiffuseRT_alt, texcoord_re, 0).rgb;

                #if MATERIAL_SPECULAR != SPECULAR_NONE
                    specularOld = textureLod(texSpecularRT_alt, texcoord_re, 0).rgb;
                #endif
            }
        #endif

        vec4 localPosLast;
        if (altFrame) {
            localPosLast = textureLod(texLocalPosLast, texcoord_re, 0);
        }
        else {
            localPosLast = textureLod(texLocalPosLast_alt, texcoord_re, 0);
        }

        float counter = localPosLast.w + 1.0;

        float offsetThreshold = clamp(depthL * 0.04, 0.0, 1.0);
        if (distance(localPos_re, localPosLast.xyz) > offsetThreshold) counter = 1.0;
        if (saturate(texcoord_re) != texcoord_re) counter = 1.0;

    	vec3 diffuseNew, specularNew;
        sampleSharedBuffer(depthL, diffuseNew, specularNew);

        // float counter = min(diffuseOld.a + 1.0, AccumMaxFrames);
        float diffuseMixF = rcp(min(counter, AccumMaxFrames));
        diffuseNew = mix(diffuseOld.rgb, diffuseNew, diffuseMixF);

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            float specularMixF = rcp(min(counter, AccumMaxFrames_specular));
            specularNew = mix(specularOld, specularNew, specularMixF);
        #endif

        counter = min(counter, 60.0);

        if (altFrame) {
            imageStore(imgDiffuseRT_alt, uv, vec4(diffuseNew, 1.0));
            imageStore(imgLocalPosLast_alt, uv, vec4(localPos, counter));

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                imageStore(imgSpecularRT_alt, uv, vec4(specularNew, 1.0));
            #endif
        }
        else {
            imageStore(imgDiffuseRT, uv, vec4(diffuseNew, 1.0));
            imageStore(imgLocalPosLast, uv, vec4(localPos, counter));

            #if MATERIAL_SPECULAR != SPECULAR_NONE
                imageStore(imgSpecularRT, uv, vec4(specularNew, 1.0));
            #endif
        }
    #else
        vec3 diffuse, specular;
        sampleSharedBuffer(depthL, diffuse, specular);

        imageStore(imgDiffuseRT, uv, vec4(diffuse, 1.0));

        #if MATERIAL_SPECULAR != SPECULAR_NONE
            imageStore(imgSpecularRT, uv, vec4(specular, 1.0));
        #endif
    #endif
}
