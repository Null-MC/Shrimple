// temp: in degrees Kelvin
vec3 blackbody(const in float temp) {
    float temp2 = _pow2(temp);

    vec2 uv = vec2(0.860117757, 0.317398726) + vec2(1.54118254e-4, 4.22806245e-5) * temp + vec2(1.28641212e-7, 4.20481691e-8) * temp2;
    uv /= 1.0 + vec2(8.42420235e-4, -2.89741816e-5) * temp + vec2(7.08145163e-7, 1.61456053e-7) * temp2;

    float w = 2.0*uv.x - 8.0*uv.y + 4.0;
    vec2 uvw = vec2(3.0, 2.0) * uv / w;

    vec3 XYZ = vec3(uvw.xy, 1.0 - (uvw.x + uvw.y));
    XYZ = vec3(rcp(XYZ.y) * XYZ.xz, 1.0).xzy;

    const mat3 XYZtoRGB = mat3(
         3.2404542, -1.5371385, -0.4985314,
        -0.9692660,  1.8760108,  0.0415560,
         0.0556434, -0.2040259,  1.0572252);

    vec3 RGB = max(XYZ * XYZtoRGB, vec3(0.0));
    return RGBToLinear(RGB);
}
