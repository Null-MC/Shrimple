#define RENDER_SHADOW_DH
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;

    #if defined RENDER_SHADOWS_ENABLED && SHADOW_TYPE == SHADOW_TYPE_CASCADED
        flat vec2 shadowTilePos;
    #endif
} vIn;

uniform int renderStage;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        vec2 p = gl_FragCoord.xy / shadowMapSize - vIn.shadowTilePos;
        if (clamp(p, vec2(0.0), vec2(0.5)) != p) discard;
    #endif
    
    outColor0 = vIn.color;
}
