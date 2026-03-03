const float groundRadiusMM = 10.360;
const float atmosphereRadiusMM = 10.388;

const float sea_level = 62.0;
const float sky_level = 962.0;

const vec3 ozoneAbsorptionBase = vec3(0.650, 1.381, 0.576);
const vec3 rayleighScatteringBase = vec3(5.802, 13.558, 33.1);
const float rayleighAbsorptionBase = 1.0;
const float mieScatteringBase = 3.996;
const float mieAbsorptionBase = 4.4;


#ifndef RENDER_SETUP
    vec3 sampleSkyTransmit(const in float world_y, const in float lightDir_y) {
        vec2 uv;
        uv.x = lightDir_y * 0.5 + 0.5;
        uv.y = (world_y - sea_level) / (sky_level - sea_level);

        uv = uv / 0.3 - 1.5;

        return textureLod(texSkyTransmit, saturate(uv), 0).rgb;
    }
#endif
