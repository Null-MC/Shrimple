const int SmokeMaxOctaves = 5;
const int SmokeTraceOctaves = 4;

float SmokeAmbientF = 0.5;
float SmokeScatterF = 8.2;
float SmokeAbsorbF  = 0.6;


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount, const in float time) {
    float sampleD = 0.0;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);

        vec3 testPos = worldPos;

        testPos.y -= time;

        testPos /= scale;

        float sampleF = textureLod(texClouds, testPos.xzy * 0.25 * (octave+1), 0).r;
        sampleD += pow(sampleF, 2.4) * rcp(exp2(octave));
    }

    const float sampleMax = rcp(1.0 - rcp(exp2(octaveCount)));
    sampleD *= sampleMax;

    //return smootherstep(sampleD);
    return _pow3(smoothstep(0.0, 1.0, sampleD)) + 0.05;
}
