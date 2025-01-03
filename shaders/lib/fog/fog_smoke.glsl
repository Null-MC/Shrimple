const int SmokeMaxOctaves = 5;
const int SmokeTraceOctaves = 4;

#ifdef WORLD_NETHER
    const float SmokeScale = 0.10;
    const float SmokeSpeed = 0.16;
    const float SmokeDensityF = 0.98;
    const float SmokeScatterF = 0.96;
    const float SmokeAbsorbF  = 0.64;
    const float SmokeAmbientF = 0.02;

    const float SmokeLevelF = WORLD_NETHER_SMOKE_LEVEL*0.01;
#else
    const float SmokeScale = 0.05;
    const float SmokeSpeed = 0.28;
    const float SmokeDensityF = 1.00;
    const float SmokeScatterF = 0.24;
    const float SmokeAbsorbF  = 0.08;
    const float SmokeAmbientF = 0.14;

    const float SmokeLevelF = WORLD_END_SMOKE_LEVEL*0.01;
#endif

const float SmokeThresholdF = 1.0 - SmokeLevelF;


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount, const in float time) {
    float sampleD = 0.008;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);
        vec3 samplePos = worldPos / scale;
        samplePos = samplePos.xzy;

        #ifdef WORLD_NETHER
            samplePos.z -= SmokeSpeed*time;
        #else
            // samplePos.xy -= vec2(0.8, 0.6) * SmokeSpeed*time;
            samplePos.z += SmokeSpeed*time;
        #endif

        samplePos *= SmokeScale;

        float sampleF = textureLod(texClouds, samplePos * (octave+1), 0).r;
        sampleD += sampleF / (octave + 2.0);// * rcp(exp2(octave));
    }

    const float sampleMaxInv = 1.0;//rcp(1.0 - rcp(exp2(octaveCount)));
    return pow(smoothstep(SmokeThresholdF, 1.0, sampleD * sampleMaxInv), 8.0);// + 0.012;
}
