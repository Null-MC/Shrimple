const vec4 U = vec4(0.1031, 0.1030, 0.0973, 0.1099);

float hash11(const in float seed) {
    float p = fract(seed * U.x);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(const in vec2 seed) {
    vec3 p3  = fract(seed.xyx * U.x);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(const in vec3 seed) {
    vec3 p3 = fract(seed * U.x);
    p3 += dot(p3, p3.zyx + 33.33); // 31.32
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(const in vec2 seed) {
    vec3 p3 = fract(seed.xyx * U.xyz);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 hash23(const in vec3 seed) {
    vec3 p3 = fract(seed * U.xyz);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash31(const in float seed) {
   vec3 p3 = fract(seed * U.xyz);
   p3 += dot(p3, p3.yzx + 33.33);
   return fract((p3.xxy + p3.yzz) * p3.zyx); 
}

vec3 hash32(const in vec2 seed) {
    vec3 p3 = fract(seed.xyx * U.xyz);
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec3 hash33(const in vec3 seed) {
    vec3 p3 = fract(seed * U.xyz);
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

vec4 hash41(const in float seed) {
    vec4 p4 = fract(seed * U);
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash42(const in vec2 seed) {
    vec4 p4 = fract(seed.xyxy * U);
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash44(const in vec4 seed) {
    vec4 p4 = fract(seed * U);
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}
