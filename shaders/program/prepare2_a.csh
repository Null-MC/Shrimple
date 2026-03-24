#include "/lib/constants.glsl"
#include "/lib/common.glsl"

const ivec2 textureSize = ivec2(WaterNormalResolution);

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(16, 16, 1);

layout(r16f) uniform writeonly image2D imgWaterHeight;

uniform float frameTimeCounter;

#include "/lib/water-waves.glsl"


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, textureSize))) return;

    vec2 texcoord = (uv + 0.5) / vec2(textureSize);

    float height = wave_fbm(texcoord, 8);

//    height = sin(texcoord.x*9.0+texcoord.y*15.0) * 0.5 + 0.5;

    height = saturate(height);
    imageStore(imgWaterHeight, uv, vec4(height));
}
