const float Shadow_DistortF = 0.08;


void distort(inout vec2 pos) {
    pos /= length(pos.xy) + Shadow_DistortF;
}
