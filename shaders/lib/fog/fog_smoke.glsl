const int SmokeMaxOctaves = 5;
const int SmokeTraceOctaves = 4;
const float SmokeSpeed = 0.05;

const float SmokeDensityF = 1.0;
const float SmokeAmbientF = 0.16;
const float SmokeScatterF = 0.48;
const float SmokeAbsorbF  = 0.64;


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount, const in float time) {
    float sampleD = 0.0;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);
        vec3 testPos = worldPos / scale;

        testPos.y -= SmokeSpeed*time;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4) * rcp(exp2(octave));
    }

    const float sampleMaxInv = rcp(1.0 - rcp(exp2(octaveCount)));
    return pow5(_smoothstep(sampleD * sampleMaxInv)) + 0.02;
}
