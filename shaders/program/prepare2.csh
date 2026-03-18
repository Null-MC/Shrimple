#include "/lib/constants.glsl"
#include "/lib/common.glsl"

const ivec2 textureSize = ivec2(WaterNormalResolution);

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
const ivec3 workGroups = ivec3(32, 32, 1);

layout(r16f) uniform writeonly image2D imgWaterHeight;

uniform float frameTimeCounter;


float gerstner_wave(vec2 uv, float freq, float amp, float speed, vec2 dir, float steepness) {
    float phase = dot(uv, dir) * freq * (2.0 * PI) + frameTimeCounter * speed;
    return amp * pow(sin(phase) * 0.5 + 0.5, steepness);
}


void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(uv, textureSize))) return;

    vec2 texcoord = (uv + 0.5) / vec2(textureSize);

    float height = 0.0;
    float freq = 3.0;    // Base integer frequency for tiling
    float amp = 0.3;     // Base amplitude
    float speed = 1.5;   // Base speed
    float steepness = 1.5; // Increases the sharpness of the crests

    for (int i = 0; i < 8; i++) {
        float angle = float(i);// * 1.25 + 0.5;
        vec2 dir = normalize(vec2(cos(angle), sin(angle)));

        height += gerstner_wave(texcoord, freq, amp, speed, dir, steepness);

        freq *= 0.996;
        amp *= 0.75;
        speed *= 1.1;
        steepness *= 1.2;
    }

    height = saturate(height);
    imageStore(imgWaterHeight, uv, vec4(height));
}
