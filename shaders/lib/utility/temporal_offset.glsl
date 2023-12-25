#if LIGHTING_TRACE_RES == 2
    const int tempOffsetSize = 4;

    const ivec2 offsetList[16] = ivec2[](
        ivec2(0, 0),
        ivec2(2, 0),
        ivec2(0, 2),
        ivec2(2, 2),

        ivec2(1, 0),
        ivec2(3, 0),
        ivec2(1, 2),
        ivec2(3, 2),

        ivec2(0, 1),
        ivec2(1, 1),
        ivec2(0, 3),
        ivec2(1, 3),

        ivec2(1, 1),
        ivec2(3, 1),
        ivec2(1, 3),
        ivec2(3, 3));
#elif LIGHTING_TRACE_RES == 1
    const int tempOffsetSize = 2;

    const ivec2 offsetList[4] = ivec2[](
        ivec2(0, 0),
        ivec2(1, 0),
        ivec2(0, 1),
        ivec2(1, 1));
#else
    const int tempOffsetSize = 1;
    const ivec2 offsetList[1] = ivec2[](ivec2(0));
#endif

ivec2 GetTemporalOffset() {
    int i = int(frameCounter + gl_FragCoord.x + tempOffsetSize*gl_FragCoord.y);
    return offsetList[i % _pow2(tempOffsetSize)];
}

ivec2 GetTemporalSampleCoord() {
    ivec2 coord = ivec2(gl_FragCoord.xy) / tempOffsetSize;
    int i = int(frameCounter + coord.x + tempOffsetSize*coord.y);
    ivec2 offset = offsetList[i % _pow2(tempOffsetSize)];
    return coord * tempOffsetSize + offset;
}
