const int SmokeMaxOctaves = 4;
const int SmokeTraceOctaves = 4;
const float SmokeSize = 8.0;

float SmokeAmbientF = 4.0;
float SmokeScatterF = 4.2;
float SmokeAbsorbF  = 0.8;


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount) {
    float sampleD = 0.0;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);

        vec3 testPos = worldPos / SmokeSize;

        testPos /= scale;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD *= sampleMax;

    //return smootherstep(sampleD);
    return _pow3(sampleD) + 0.05;
}
