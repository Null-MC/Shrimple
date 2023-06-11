vec3 SampleLpvLinear(const in vec3 lpvTexcoord) {
    return (frameCounter % 2) == 0
        ? textureLod(texLPV_1, lpvTexcoord, 0).rgb
        : textureLod(texLPV_2, lpvTexcoord, 0).rgb;
}

vec3 SampleLpvPoint(const in ivec3 lpvPos) {
    return (frameCounter % 2) == 0
        ? texelFetch(texLPV_1, lpvPos, 0).rgb
        : texelFetch(texLPV_2, lpvPos, 0).rgb;
}

float LpvVoxelTest(const in ivec3 voxelCoord) {
    ivec3 gridCell = ivec3(floor(voxelCoord / LIGHT_BIN_SIZE));
    uint gridIndex = GetSceneLightGridIndex(gridCell);
    ivec3 blockCell = voxelCoord - gridCell * LIGHT_BIN_SIZE;

    uint blockId = GetSceneBlockMask(blockCell, gridIndex);
    return IsTraceEmptyBlock(blockId) ? 1.0 : 0.0;
}

vec3 SampleLpvVoxel(const in vec3 voxelPos, const in vec3 lpvPos) {
    #if LPV_SAMPLE_MODE == LPV_SAMPLE_POINT
        return SampleLpvPoint(ivec3(lpvPos));
    #elif LPV_SAMPLE_MODE == LPV_SAMPLE_LINEAR
        vec3 lpvTexcoord = GetLPVTexCoord(lpvPos);
        return SampleLpvLinear(lpvTexcoord);
    #elif LPV_SAMPLE_MODE == LPV_SAMPLE_VOXEL
        ivec3 lpvCoord = ivec3(lpvPos - 0.5 + 0.01);
        vec3 lpvF = saturate(lpvPos - lpvCoord - 0.5);

        ivec3 voxelCoord = ivec3(voxelPos - 0.5 + 0.01);

        vec3 sample_x1y1z1 = SampleLpvPoint(lpvCoord + ivec3(0, 0, 0));
        vec3 sample_x2y1z1 = SampleLpvPoint(lpvCoord + ivec3(1, 0, 0));
        vec3 sample_x1y2z1 = SampleLpvPoint(lpvCoord + ivec3(0, 1, 0));
        vec3 sample_x2y2z1 = SampleLpvPoint(lpvCoord + ivec3(1, 1, 0));

        vec3 sample_x1y1z2 = SampleLpvPoint(lpvCoord + ivec3(0, 0, 1));
        vec3 sample_x2y1z2 = SampleLpvPoint(lpvCoord + ivec3(1, 0, 1));
        vec3 sample_x1y2z2 = SampleLpvPoint(lpvCoord + ivec3(0, 1, 1));
        vec3 sample_x2y2z2 = SampleLpvPoint(lpvCoord + ivec3(1, 1, 1));

        float voxel_x1y1z1 = LpvVoxelTest(voxelCoord + ivec3(0, 0, 0));
        float voxel_x2y1z1 = LpvVoxelTest(voxelCoord + ivec3(1, 0, 0));
        float voxel_x1y2z1 = LpvVoxelTest(voxelCoord + ivec3(0, 1, 0));
        float voxel_x2y2z1 = LpvVoxelTest(voxelCoord + ivec3(1, 1, 0));

        float voxel_x1y1z2 = LpvVoxelTest(voxelCoord + ivec3(0, 0, 1));
        float voxel_x2y1z2 = LpvVoxelTest(voxelCoord + ivec3(1, 0, 1));
        float voxel_x1y2z2 = LpvVoxelTest(voxelCoord + ivec3(0, 1, 1));
        float voxel_x2y2z2 = LpvVoxelTest(voxelCoord + ivec3(1, 1, 1));

        sample_x1y1z1 *= voxel_x1y1z1;
        sample_x2y1z1 *= voxel_x2y1z1;
        sample_x1y2z1 *= voxel_x1y2z1;
        sample_x2y2z1 *= voxel_x2y2z1;

        sample_x1y1z2 *= voxel_x1y1z2;
        sample_x2y1z2 *= voxel_x2y1z2;
        sample_x1y2z2 *= voxel_x1y2z2;
        sample_x2y2z2 *= voxel_x2y2z2;

        // TODO: Add special checks for avoiding diagonal blending between occluded edges/corners

        vec3 sample_y1z1 = mix(sample_x1y1z1, sample_x2y1z1, lpvF.x);
        vec3 sample_y2z1 = mix(sample_x1y2z1, sample_x2y2z1, lpvF.x);

        vec3 sample_y1z2 = mix(sample_x1y1z2, sample_x2y1z2, lpvF.x);
        vec3 sample_y2z2 = mix(sample_x1y2z2, sample_x2y2z2, lpvF.x);

        vec3 sample_z1 = mix(sample_y1z1, sample_y2z1, lpvF.y);
        vec3 sample_z2 = mix(sample_y1z2, sample_y2z2, lpvF.y);

        return mix(sample_z1, sample_z2, lpvF.z);
    #endif
}
