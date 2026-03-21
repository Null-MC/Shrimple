#include "/lib/constants.glsl"
#include "/lib/common.glsl"

const ivec2 textureSize = ivec2(WaterNormalResolution);

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 16, 1);

layout(r16f) uniform writeonly image2D imgWaterHeight;

uniform sampler2D texWaterHeight;


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, textureSize))) return;

    ivec2 uv_wrapped = textureSize - uv;
    float dest = texelFetch(texWaterHeight, uv, 0).r;
    float src_y = texelFetch(texWaterHeight, ivec2(uv.x, uv_wrapped.y), 0).r;

    vec2 texcoord = (uv + 0.5) / vec2(textureSize);
    vec2 F = max(texcoord*4.0 - 3.0, 0.0);
    F = smoothstep(0.0, 1.0, F);

    dest = mix(dest, src_y, F.y);

    imageStore(imgWaterHeight, uv, vec4(dest));
}
