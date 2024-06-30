// #define ERP_FOCUS

const vec2 TAU_PI = vec2(TAU, PI);
const vec2 TAU_PI_INV = rcp(TAU_PI);

vec3 DirectionFromUV(in vec2 uv) {
    #ifdef ERP_FOCUS
        uv.y = uv.y * 2.0 - 1.0;
        uv.y = _pow2(uv.y) * sign(uv.y);
        uv.y = uv.y * 0.5 + 0.5;
    #endif

    vec2 sphereCoord = (uv - vec2(0.5, 0.0)) * TAU_PI;

    vec2 _sin = sin(sphereCoord);
    vec2 _cos = cos(sphereCoord);
    
    return vec3(_cos.xy, _sin.x) * vec3(_sin.y, 1.0, _sin.y);
}

vec2 DirectionToUV(const in vec3 dir) {
    if (dir.y >  0.9999) return vec2(0.5, 0.0);
    if (dir.y < -0.9999) return vec2(0.5, 1.0);

    vec2 uv = vec2(
        atan(dir.z, dir.x),
        acos(dir.y));

    uv = (uv * TAU_PI_INV) + vec2(0.5, 0.0);

    #ifdef ERP_FOCUS
        uv.y = uv.y * 2.0 - 1.0;
        uv.y = sqrt(abs(uv.y)) * sign(uv.y);
        uv.y = uv.y * 0.5 + 0.5;
    #endif

    return uv;
}
