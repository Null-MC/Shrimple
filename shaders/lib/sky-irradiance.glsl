vec3 SampleSkyIrradiance(const in vec3 localNormal) {
    ivec3 dir = ivec3(step(vec3(0.0), localNormal));
    ivec3 t_dir = ivec3(0, 2, 4) + dir;
    vec3 dir_y = (t_dir + 0.5) / 6.0;

    float sun_y = sunLocalDir.y * 0.5 + 0.5;

    vec2 tx = vec2(sun_y, dir_y.x);
    vec2 ty = vec2(sun_y, dir_y.y);
    vec2 tz = vec2(sun_y, dir_y.z);

    vec3 sx = textureLod(texSkyIrradiance, tx, 0).rgb;
    vec3 sy = textureLod(texSkyIrradiance, ty, 0).rgb;
    vec3 sz = textureLod(texSkyIrradiance, tz, 0).rgb;

    vec3 a_normal = abs(localNormal);
    return sx*a_normal.x + sy*a_normal.y + sz*a_normal.z;
}
