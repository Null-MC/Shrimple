#define diag3(v) mat3((v).x, 0.0, 0.0, 0.0, (v).y, 0.0, 0.0, 0.0, (v).z)
#define xy_to_XYZ(x, y) vec3(x/y, 1.0, (1.0 - x - y)/y)

const float b = 1.15;
const float g = 0.66;
const float c1 = 3424.0/exp2(12.0);
const float c2 = 2413.0/exp2(7.0);
const float c3 = 2392.0/exp2(7.0);
const float n = 2610.0/exp2(14.0);
const float p = 1.7*2523.0/exp2(5.0);
const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

const vec3 D65 = xy_to_XYZ(0.31271, 0.32902);
const mat3 sRGB = mat3(xy_to_XYZ(0.64, 0.33), xy_to_XYZ(0.30, 0.60), xy_to_XYZ(0.15, 0.06));
const mat3 sRGB_TO_XYZ_D65 = sRGB*diag3(inverse(sRGB)*D65);
const mat3 XYZ_D65_TO_sRGB = inverse(sRGB_TO_XYZ_D65);

const mat3 LMS_TO_Iab = mat3(
    +0.5, +3.524000, +0.199076,
    +0.5, -4.066708, +1.096799,
    +0.0, +0.542708, -1.295875
);

const mat3 XYZ_D65_TO_LMS = 1e2/1e4 * mat3(
    +0.41478972, -0.20151000, -0.01660080,
    +0.57999900, +1.12064900, +0.26480000,
    +0.01464800, +0.05310080, +0.66847990
) * mat3(b, 1.0-g, 0.0, 0.0, g, 0.0, 1.0-b, 0.0, 1.0);

vec3 XYZ_D65_to_Jab(const in vec3 XYZ) {
    vec3 LMS = XYZ_D65_TO_LMS * XYZ;
    vec3 LMSpp = pow(LMS, vec3(n));
    vec3 LMSp = pow((c1 + c2*LMSpp) / (1.0 + c3*LMSpp), vec3(p));
    vec3 Iab = LMS_TO_Iab * LMSp;
    float J = (1.0 + d) * Iab.x / (1.0 + d*Iab.x) - d0;
    return vec3(J, Iab.yz);
}

vec3 Jab_to_XYZ_D65(const in vec3 Jab) {
    float I = (Jab.x + d0) / (1.0 + d - d*(Jab.x + d0));
    vec3 LMSp = inverse(LMS_TO_Iab) * vec3(I, Jab.yz);
    vec3 LMSpp = pow(LMSp, vec3(rcp(p)));
    vec3 LMS = pow((c1 - LMSpp) / (c3*LMSpp - c2), vec3(1.0/n));
    return inverse(XYZ_D65_TO_LMS) * LMS;
}

vec3 RgbToJab(const in vec3 sRGB) {
     return XYZ_D65_to_Jab(sRGB_TO_XYZ_D65 * sRGB);
}

vec3 JabToRgb(const in vec3 Jab) {
     return XYZ_D65_TO_sRGB * Jab_to_XYZ_D65(Jab);
}
