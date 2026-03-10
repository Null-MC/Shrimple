vec3 SampleSkyIrradiance(const in vec3 localNormal) {
    bvec3 dir = greaterThanEqual(localNormal, vec3(0.0));
    ivec3 t_dir = ivec3(0, 2, 4) + ivec3(dir);
    vec3 dir_y = (t_dir + 0.5) / 6.0;

    float sun_y = sunLocalDir.y * 0.5 + 0.5;

    float rain = rainStrength * 0.5 + 0.25;

    vec3 sx = texture(texSkyIrradiance, vec3(sun_y, dir_y.x, rain)).rgb;
    vec3 sy = texture(texSkyIrradiance, vec3(sun_y, dir_y.y, rain)).rgb;
    vec3 sz = texture(texSkyIrradiance, vec3(sun_y, dir_y.z, rain)).rgb;

    vec3 abs_normal = abs(localNormal);
    vec3 irradiance = sx*abs_normal.x + sy*abs_normal.y + sz*abs_normal.z;

    // fake ground occlusion
//    float groundOcclusion = min(localNormal.y + 1.0, 1.0);
//    groundOcclusion = mix(groundOcclusion, 1.0, altitude);

    return irradiance;// * groundOcclusion;
}
