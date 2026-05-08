// Blackbody color by correlated color temperature (Kelvin)
// Uses CIE 1960-2 approximation (Bruce Lindbloom piecewise) to compute xy chromaticity from CCT,
// converts to XYZ (Y=1), then to linear sRGB. Result is normalized to max=1 and returned in linear space.
vec3 blackbody(const in float temperature) {
    // Valid range for the approximation: 1667K..25000K
    float T = clamp(temperature, 1667.0, 25000.0);

    // Compute chromaticity x using piecewise approximation
    float T2 = T * T;
    float T3 = T2 * T;
    float x;
    if (T <= 4000.0) {
        x = (-0.2661239e9) / T3 - (0.2343580e6) / T2 + (0.8776956e3) / T + 0.179910;
    } else {
        x = (-3.0258469e9) / T3 + (2.1070379e6) / T2 + (0.2226347e3) / T + 0.240390;
    }

    // Compute chromaticity y from x (piecewise)
    float x2 = x * x;
    float x3 = x2 * x;
    float y;
    if (T <= 2222.0) {
        y = -1.1063814 * x3 - 1.34811020 * x2 + 2.18555832 * x - 0.20219683;
    } else if (T <= 4000.0) {
        y = -0.9549476 * x3 - 1.37418593 * x2 + 2.09137015 * x - 0.16748867;
    } else {
        y = 3.0817580 * x3 - 5.87338670 * x2 + 3.75112997 * x - 0.37001483;
    }

    vec3 XYZ;
    XYZ.y = 1.0;
    XYZ.x = (XYZ.y / y) * x;
    XYZ.z = (XYZ.y / y) * (1.0 - x - y);

    const mat3 XYZ_TO_RGB = mat3(
        vec3(3.2406, -0.9689, 0.0557),
        vec3(-1.5372, 1.8758, -0.2040),
        vec3(-0.4986, 0.0415, 1.0570)
    );

    vec3 rgb = max(XYZ_TO_RGB * XYZ, vec3(0.0));

    float m = max(max(rgb.r, rgb.g), rgb.b);
    if (m > 0.0) rgb /= m;

    return rgb;
}
