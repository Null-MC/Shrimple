// temperature: degrees Kelvin

vec3 blackbody(const in float temperature) {
    vec3 color = vec3(255.0);
    float t = temperature / 100.0;

    // Red component
    if (t <= 66.0) {
        color.r = 255.0;
    } else {
        color.r = t - 60.0;
        color.r = 329.698727446 * pow(color.r, -0.1332047592);
    }

    // Green component
    if (t <= 66.0) {
        color.g = t;
        color.g = 99.4708025861 * log(color.g) - 161.1195681661;
    } else {
        color.g = t - 60.0;
        color.g = 288.1221695283 * pow(color.g, -0.0755148492);
    }

    // Blue component
    if (t >= 66.0) {
        color.b = 255.0;
    } else if (t <= 19.0) {
        color.b = 0.0;
    } else {
        color.b = t - 10.0;
        color.b = 138.5177312231 * log(color.b) - 305.0447927307;
    }

    color = saturate(color / 255.0);
    color = RGBToLinear(color);
    return color;
}
