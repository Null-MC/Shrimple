void GetBlockColorRange(const in uint blockId, out vec3 lightColor, out float lightRange) {
    ivec2 blockLightUV = ivec2(blockId % 256, blockId / 256);
    vec4 lightColorRange = texelFetch(texBlockLight, blockLightUV, 0);
    lightColor = RGBToLinear(lightColorRange.rgb);
    lightRange = lightColorRange.a * 32.0;
}
