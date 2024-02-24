struct QuadFace {        // 76 x1280 =97280
    // ?
};

#ifdef RENDER_SETUP
    layout(binding = 5) writeonly buffer playerQuadData
#else
    layout(binding = 5) readonly buffer playerQuadData
#endif
{
    uint PlayerQuadCount;           // 4
    QuadFace PlayerQuadList[];      // ?
};
