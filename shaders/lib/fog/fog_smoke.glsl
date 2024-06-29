const int SmokeMaxOctaves = 5;
const int SmokeTraceOctaves = 4;

#ifdef WORLD_NETHER
    const float SmokeScale = 0.10;
    const float SmokeSpeed = 0.16;
    const float SmokeDensityF = 0.98;
    const float SmokeScatterF = 0.96;
    const float SmokeAbsorbF  = 0.64;
    const float SmokeAmbientF = 0.02;
#else
    const float SmokeScale = 0.05;
    const float SmokeSpeed = 0.22;
    const float SmokeDensityF = 0.58;
    const float SmokeScatterF = 0.76;
    const float SmokeAbsorbF  = 0.24;
    const float SmokeAmbientF = 0.09;
#endif


float SampleSmokeOctaves(in vec3 worldPos, const in int octaveCount, const in float time) {
    float sampleD = 0.008;

    for (int octave = 0; octave < octaveCount; octave++) {
        float scale = exp2(SmokeMaxOctaves - octave);
        vec3 samplePos = worldPos / scale;

        #ifdef WORLD_NETHER
            samplePos = samplePos.xzy;
        #endif

        samplePos.z -= SmokeSpeed*time;
        samplePos *= SmokeScale;

        float sampleF = textureLod(texClouds, samplePos * (octave+1), 0).r;
        sampleD += sampleF / (octave + 2.0);// * rcp(exp2(octave));
    }

    const float sampleMaxInv = 1.0;//rcp(1.0 - rcp(exp2(octaveCount)));
    return pow(_smoothstep(sampleD * sampleMaxInv), 24.0);// + 0.012;
}
