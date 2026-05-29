// https://www.shadertoy.com/view/tdSXzD

const float Sky_StarRes = 512.0;
const float Sky_StarSpeed = 1.2;
const float Sky_StarBrightness = 8.0;
const float Sky_StarTempMin = 2000.0;
const float Sky_StarTempMax = 30000.0;


vec2 hash23_stars(in vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.27);
    return fract(p.x * p.yz);
}

float noise(const in vec2 v) {
    return textureLod(noisetex, (v + 0.5) / 256.0, 0).r;
}

vec3 getStarDir(const in vec3 localViewDir) {
    mat3 matAngleRot = rotateX(-radians(sunPathRotation));
    mat3 matTimeRot = rotateZ(PI*2.0 * sunAngle * Sky_StarSpeed);
    return matTimeRot * (matAngleRot * localViewDir);
}

vec3 GetStarLight(const in vec3 localViewDir) {
    const float StarTempRange = Sky_StarTempMax - Sky_StarTempMin;

    vec3 dir = getStarDir(localViewDir);
    vec3 color = vec3(0.0);

    for (int i = 0; i < SKY_STAR_LAYERS; i++) {
        vec3 q = fract(dir * Sky_StarRes) - 0.5;
        vec3 id = floor(dir * Sky_StarRes);
        vec2 rn = hash23_stars(id);
        float c2 = 1.0 - smoothstep(0.0, 0.6, length(q));
        c2 *= step(rn.x, 0.0005 + pow2(i) * 0.001);

        float layer_scale = 1.0 / (1.0 + i+rn.y);
        float temp = StarTempRange * pow(layer_scale, 2.0) + Sky_StarTempMin;
        float falloff = c2 * pow(layer_scale, 3.0);

        color += blackbody(temp) * falloff;

        dir *= 1.2;
    }

    return color * Sky_StarBrightness;
}
