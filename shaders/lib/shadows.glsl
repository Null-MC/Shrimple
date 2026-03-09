const float Shadow_DistortF = 0.08;

//#ifdef PHOTONICS_GI_ENABLED
//    const float shadowAmbientF = 0.0;
//#else
//    const float shadowAmbientF = SHADOW_AMBIENT * 0.01;
//#endif


void distort(inout vec2 pos) {
    pos /= length(pos.xy) + Shadow_DistortF;
}
