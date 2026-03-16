#ifdef PHOTONICS_SHRIMPLE_COLORS
    uniform sampler2D texBlockLight;
#endif


void modify_light(inout Light light, vec3 world_pos) {
    #ifdef PHOTONICS_SHRIMPLE_COLORS
        ivec2 blockLightUV = ivec2(light.blockId % 256, light.blockId / 256);
        vec4 lightColorRange = texelFetch(texBlockLight, blockLightUV, 0);
        vec3 lightColor = RGBToLinear(lightColorRange.rgb);
        float lightRange = lightColorRange.a * 32.0;

        light.color = (lightRange / 15.0) * lightColor;
        light.block_radius = 1.5 * lightRange;
    #else
        light.color /= light.intensity;

        light.color = RGBToLinear(saturate(light.color));

        light.color *= light.intensity;

        //    light.attenuation = vec2(0.0, 0.5);
    #endif
}
