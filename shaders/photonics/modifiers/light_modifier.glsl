#ifdef PHOTONICS_SHRIMPLE_COLORS
    uniform sampler2D texBlockLight;

    #include "/lib/sampling/block-light.glsl"
#endif


void modify_light(inout Light light, vec3 world_pos) {
    #ifdef PHOTONICS_SHRIMPLE_COLORS
        vec3 lightColor;
        float lightRange;
        GetBlockColorRange(light.blockId, lightColor, lightRange);

        light.color = (lightRange / 15.0) * lightColor;
        light.block_radius = lightRange;
    #else
        light.color /= light.intensity;

        light.color = RGBToLinear(saturate(light.color));

        light.color *= light.intensity;

        //    light.attenuation = vec2(0.0, 0.5);
    #endif

    light.color *= 8.0;
}
