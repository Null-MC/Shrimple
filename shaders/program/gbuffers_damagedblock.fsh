#define RENDER_DAMAGEDBLOCK
#define RENDER_GBUFFER
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 glcolor;
in vec3 vLocalPos;
in vec2 vLocalCoord;
in vec3 vLocalNormal;
in vec3 vLocalTangent;
in float vTangentW;

flat in mat2 atlasBounds;

#if MATERIAL_PARALLAX != PARALLAX_NONE
    in vec3 tanViewPos;
#endif

uniform sampler2D gtexture;
uniform sampler2D depthtex0;

#if MATERIAL_NORMALS == NORMALMAP_OLDPBR || MATERIAL_NORMALS == NORMALMAP_LABPBR || MATERIAL_PARALLAX != PARALLAX_NONE || MATERIAL_OCCLUSION == OCCLUSION_LABPBR
    uniform sampler2D normals;
#endif

uniform ivec2 atlasSize;
uniform float near;
uniform float far;

#if MC_VERSION >= 11700 && defined ALPHATESTREF_ENABLED
    uniform float alphaTestRef;
#endif

#include "/lib/sampling/atlas.glsl"
#include "/lib/sampling/depth.glsl"
#include "/lib/sampling/ign.glsl"
#include "/lib/utility/tbn.glsl"

#if MATERIAL_PARALLAX != PARALLAX_NONE
    #include "/lib/sampling/linear.glsl"
    #include "/lib/material/parallax.glsl"
#endif


#if defined DEFERRED_BUFFER_ENABLED && defined DEFER_TRANSLUCENT
    /* RENDERTARGETS: 1 */
#else
    /* RENDERTARGETS: 0 */
#endif
layout(location = 0) out vec4 outFinal;

void main() {
    mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
    float viewDist = length(vLocalPos);
    vec2 atlasCoord = texcoord;
    vec2 localCoord = vLocalCoord;
    
    vec3 localNormal = normalize(vLocalNormal);

    bool skipParallax = false;

    #if MATERIAL_PARALLAX != PARALLAX_NONE
        //bool isMissingNormal = all(lessThan(normalMap.xy, EPSILON2));
        //bool isMissingTangent = any(isnan(vLocalTangent));

        float texDepth = 1.0;
        vec3 traceCoordDepth = vec3(1.0);
        vec3 tanViewDir = normalize(tanViewPos);

        if (!skipParallax && viewDist < MATERIAL_PARALLAX_DISTANCE) {
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
        float depthOpaqueLinear = linearizeDepthFast(depthOpaque, near, far);
        float depthLinear = rcp(gl_FragCoord.w);

        if (abs(depthLinear - depthOpaqueLinear) > 0.2) {
            discard;
            return;
        }
    #endif

    color.rgb *= glcolor.rgb;

    #if DEBUG_VIEW == DEBUG_VIEW_WHITEWORLD
        color.rgb = vec3(WHITEWORLD_VALUE);
    #endif

    color.rgb = RGBToLinear(color.rgb);

    outFinal = color;
}
