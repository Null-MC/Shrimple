#define RENDER_SHADOW
#define RENDER_FRAG

#include "/lib/constants.glsl"
#include "/lib/common.glsl"

#if SHADOW_TYPE == SHADOW_TYPE_CASCADED
    in VertexData {
        flat vec2 shadowTilePos;
    } vIn;
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

void main() {
    #if SHADOW_TYPE == SHADOW_TYPE_CASCADED
        vec2 p = gl_FragCoord.xy / shadowMapSize - vIn.shadowTilePos;
        if (clamp(p, vec2(0.0), vec2(0.5)) != p) discard;
    #endif
    
    outColor0 = vec4(0.90, 0.94, 0.96, 0.0);
}
