#ifdef PHOTONICS_SHRIMPLE_COLORS
    uniform sampler2D texBlockLight;

    #include "/lib/sampling/block-light.glsl"
#endif


void modify_light(inout Light light, vec3 world_pos) {
    #ifdef PHOTONICS_SHRIMPLE_COLORS
        if (light.blockId > 0 && light.blockId < USHORT_MAX) {
            GetBlockColorRange(light.blockId, light.color, light.block_radius);
            light.color = (light.block_radius / 15.0) * light.color;
        }
    #else
        light.color /= light.intensity;

        light.color = RGBToLinear(saturate(light.color));

        light.color *= light.intensity;

        //    light.attenuation = vec2(0.0, 0.5);
    #endif

    light.color *= 8.0;
}
