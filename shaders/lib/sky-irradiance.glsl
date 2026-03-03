vec3 SampleSkyIrradiance(const in vec3 localNormal) {
    bvec3 dir = greaterThanEqual(localNormal, vec3(0.0));
    ivec3 t_dir = ivec3(0, 2, 4) + ivec3(dir);
    vec3 dir_y = (t_dir + 0.5) / 6.0;

    float sun_y = sunLocalDir.y * 0.5 + 0.5;

    vec3 sx = texture(texSkyIrradiance, vec2(sun_y, dir_y.x)).rgb;
    vec3 sy = texture(texSkyIrradiance, vec2(sun_y, dir_y.y)).rgb;
    vec3 sz = texture(texSkyIrradiance, vec2(sun_y, dir_y.z)).rgb;

    vec3 abs_normal = abs(localNormal);
    return sx*abs_normal.x + sy*abs_normal.y + sz*abs_normal.z;
}
