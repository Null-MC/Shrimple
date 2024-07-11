// https://www.shadertoy.com/view/tdSXzD

const int Sky_StarLayers = 3; // [1 2 3 4 5]
const float Sky_StarRes = 512.0;
const float Sky_StarSpeed = 1.2;
const float Sky_StarBrightness = 8.0;
const float Sky_StarTempMin = 2000.0;
const float Sky_StarTempMax = 30000.0;


vec3 hash33_stars(in vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.27);
    return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z));
}

float noise(const in vec2 v) { 
    return textureLod(noisetex, (v + 0.5) / 256.0, 0.0).r; 
}

vec3 GetStarLight(const in vec3 viewDir) {
    const float StarTempRange = Sky_StarTempMax - Sky_StarTempMin;

    vec3 final = vec3(0.0);
    vec3 D1 = viewDir;

	for (int i = 0; i < Sky_StarLayers; i++) {
        vec3 q = fract(D1 * Sky_StarRes) - 0.5;
        vec3 id = floor(D1 * Sky_StarRes);
        vec2 rn = hash33_stars(id).xy;
        float c2 = 1.0 - smoothstep(0.0, 0.6, length(q));
        c2 *= step(rn.x, 0.0005 + pow2(i) * 0.001);

        float layer_scale = rcp(1.0 + i+rn.y);
        float temp = StarTempRange * pow(layer_scale, 2.0) + Sky_StarTempMin;
        float falloff = c2 * pow(layer_scale, 3.0);

        final += blackbody(temp) * falloff;

        D1 *= 1.2;
    }

    return final * Sky_StarBrightness;
}
