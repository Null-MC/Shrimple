#define RENDER_DAMAGEDBLOCK
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;
    vec2 localCoord;
    vec3 localNormal;
    vec4 localTangent;

    flat mat2 atlasBounds;

    #ifdef PARALLAX_ENABLED
        vec3 viewPos_T;
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D depthtex0;

#if MATERIAL_NORMALS == NORMALMAP_OLDPBR || MATERIAL_NORMALS == NORMALMAP_LABPBR || defined PARALLAX_ENABLED || MATERIAL_OCCLUSION == OCCLUSION_LABPBR
    uniform sampler2D normals;
#endif

uniform ivec2 atlasSize;
uniform int frameCounter;
uniform float near;
uniform float far;

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/utility/tbn.glsl"

#ifdef PARALLAX_ENABLED
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif


#if defined DEFERRED_BUFFER_ENABLED //&& defined DEFER_TRANSLUCENT
    /* RENDERTARGETS: 15 */
#else
    /* RENDERTARGETS: 0 */
#endif
layout(location = 0) out vec4 outFinal;

void main() {
    mat2 dFdXY = mat2(dFdx(vIn.texcoord), dFdy(vIn.texcoord));
    float viewDist = length(vIn.localPos);
    vec2 atlasCoord = vIn.texcoord;
    vec2 localCoord = vIn.localCoord;
    
    vec3 localNormal = normalize(vIn.localNormal);

    bool skipParallax = false;

    #ifdef PARALLAX_ENABLED
        //bool isMissingNormal = all(lessThan(normalMap.xy, EPSILON2));
        //bool isMissingTangent = any(isnan(vLocalTangent));

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(vIn.viewPos_T);

        if (!skipParallax && viewDist < MATERIAL_DISPLACE_MAX_DIST) {
            atlasCoord = GetParallaxCoord(localCoord, dFdXY, tanViewDir, viewDist, texDepth, traceCoordDepth);
        }
    #endif

    vec4 color = textureGrad(gtexture, atlasCoord, dFdXY[0], dFdXY[1]);

    if (color.a < alphaTestRef) {
        discard;
        return;
    }

    #ifdef DAMAGE_DEPTH_CHECK
        float depthOpaque = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
        float depthOpaqueLinear = linearizeDepth(depthOpaque, near, farPlane);
        float depthLinear = rcp(gl_FragCoord.w);

        if (abs(depthLinear - depthOpaqueLinear) > 0.2) {
            discard;
            return;
        }
    #endif

    color.rgb *= vIn.color.rgb;

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    color.rgb = RGBToLinear(color.rgb);

    outFinal = color;
}
