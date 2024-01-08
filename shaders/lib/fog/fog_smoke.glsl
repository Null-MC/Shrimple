const int SmokeMaxOctaves = 5;
const int SmokeTraceOctaves = 4;
const float SmokeSpeed = 0.05;

const float SmokeDensityF = 32.0;
const float SmokeAmbientF = 0.02;
const float SmokeScatterF = 0.16;
const float SmokeAbsorbF  = 0.02;


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount, const in float time) {
    float sampleD = 0.0;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);

        vec3 testPos = worldPos;

        testPos /= scale;

        testPos.y -= SmokeSpeed*time;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD *= sampleMax;

    //return smootherstep(sampleD);
    return pow5(_smoothstep(sampleD));// + 0.04;
}
