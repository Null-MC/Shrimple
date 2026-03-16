void modify_light(inout Light light, vec3 world_pos) {
    light.color /= light.intensity;

    light.color = RGBToLinear(light.color);

    light.color *= light.intensity;

//    light.attenuation = vec2(0.0, 0.5);
}
