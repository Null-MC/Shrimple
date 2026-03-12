#include "/lib/constants.glsl"
#include "/lib/common.glsl"

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

#if   BLOOM_TILE == 0
    const vec2 workGroupsRender = vec2(1.0, 1.0);
#elif BLOOM_TILE == 1
    const vec2 workGroupsRender = vec2(0.5, 0.5);
#elif BLOOM_TILE == 2
    const vec2 workGroupsRender = vec2(0.25, 0.25);
#elif BLOOM_TILE == 3
    const vec2 workGroupsRender = vec2(0.125, 0.125);
#elif BLOOM_TILE == 4
    const vec2 workGroupsRender = vec2(0.0625, 0.0625);
#elif BLOOM_TILE == 5
    const vec2 workGroupsRender = vec2(0.03125, 0.03125);
#elif BLOOM_TILE == 6
    const vec2 workGroupsRender = vec2(0.015625, 0.015625);
#elif BLOOM_TILE == 7
    const vec2 workGroupsRender = vec2(0.0078125, 0.0078125);
#endif

layout(rgba16f) uniform writeonly image2D IMG_DEST;

uniform sampler2D TEX_BLOOM_TILES;

#if BLOOM_TILE == 0
    uniform sampler2D TEX_DEST;
#endif

uniform vec2 viewSize;

#include "/lib/bloom.glsl"


vec3 BloomSample(in vec2 texcoord, const in vec2 boundsMin, const in vec2 boundsMax) {
    texcoord = clamp(texcoord, boundsMin, boundsMax);
    return texture(TEX_BLOOM_TILES, texcoord).rgb;
}


void main() {
    ivec2 outputSize = ivec2(ceil(viewSize / exp2(BLOOM_TILE)));

    ivec2 local_uv = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(local_uv, outputSize))) return;

    vec2 pixelSize = 1.0 / viewSize;

    vec2 texcoord = (gl_GlobalInvocationID.xy + 0.5) / outputSize;
//    vec3 bloom = BloomTileUpsample(TEX_BLOOM_TILES, texcoord, BLOOM_TILE);

    vec2 tex = texcoord - 0.5 * pixelSize;

    vec2 srcBoundsMin, srcBoundsMax;
    GetBloomTileInnerBounds(BLOOM_TILE, srcBoundsMin, srcBoundsMax);
    tex = mix(srcBoundsMin, srcBoundsMax, tex);

    const float filterRadius = 0.001 / exp2(BLOOM_TILE); // [0.0004 0.0008]
    float x = filterRadius * (viewSize.y / viewSize.x);
    float y = filterRadius;

    vec3 a = BloomSample(vec2(tex.x - x, tex.y + y), srcBoundsMin, srcBoundsMax);
    vec3 b = BloomSample(vec2(tex.x,     tex.y + y), srcBoundsMin, srcBoundsMax);
    vec3 c = BloomSample(vec2(tex.x + x, tex.y + y), srcBoundsMin, srcBoundsMax);

    vec3 d = BloomSample(vec2(tex.x - x, tex.y), srcBoundsMin, srcBoundsMax);
    vec3 e = BloomSample(vec2(tex.x,     tex.y), srcBoundsMin, srcBoundsMax);
    vec3 f = BloomSample(vec2(tex.x + x, tex.y), srcBoundsMin, srcBoundsMax);

    vec3 g = BloomSample(vec2(tex.x - x, tex.y - y), srcBoundsMin, srcBoundsMax);
    vec3 h = BloomSample(vec2(tex.x,     tex.y - y), srcBoundsMin, srcBoundsMax);
    vec3 i = BloomSample(vec2(tex.x + x, tex.y - y), srcBoundsMin, srcBoundsMax);

    vec3 upsample;
    upsample = e*4.0;
    upsample += (b+d+f+h)*2.0;
    upsample += (a+c+g+i);
    upsample *= 0.0625;

    vec3 bloom = max(upsample, vec3(0.0));




    #if BLOOM_TILE > 0
        vec2 dstBoundsMin, dstBoundsMax;
        GetBloomTileInnerBounds(BLOOM_TILE-1, dstBoundsMin, dstBoundsMax);
        texcoord = mix(dstBoundsMin, dstBoundsMax, texcoord);
    #endif

    vec3 color = texture(TEX_DEST, texcoord).rgb;

    #if BLOOM_TILE == 0
        bloom *= EffectBloomStrengthF;
    #endif

    color += bloom;

    ivec2 output_uv = local_uv;

    #if BLOOM_TILE > 0
//        vec2 outputPos = GetBloomTileInnerPosition(BLOOM_TILE-1);
        output_uv += ivec2(dstBoundsMin * viewSize + EPSILON);
    #endif

    imageStore(IMG_DEST, output_uv, vec4(color, 1.0));
}
