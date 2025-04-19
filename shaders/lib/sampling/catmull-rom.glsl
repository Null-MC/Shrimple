vec4 sample_CatmullRom(const in sampler2D texSampler, const in vec2 uv, const in vec2 bufferSize) {
    vec2 samplePos = uv * bufferSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / max(w12, 0.001);

    w0 = saturate(w0);
    w12 = saturate(w12);
    w3 = saturate(w3);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 pixelSize = rcp(bufferSize);

    vec2 texPos0  = (texPos1 - 1.0) * pixelSize;
    vec2 texPos3  = (texPos1 + 2.0) * pixelSize;
    vec2 texPos12 = (texPos1 + offset12) * pixelSize;

    vec4 result = vec4(0.0);

    result += textureLod(texSampler, vec2(texPos0.x,  texPos0.y), 0) * w0.x * w0.y;
    result += textureLod(texSampler, vec2(texPos12.x, texPos0.y), 0) * w12.x * w0.y;
    result += textureLod(texSampler, vec2(texPos3.x,  texPos0.y), 0) * w3.x * w0.y;

    result += textureLod(texSampler, vec2(texPos0.x,  texPos12.y), 0) * w0.x * w12.y;
    result += textureLod(texSampler, vec2(texPos12.x, texPos12.y), 0) * w12.x * w12.y;
    result += textureLod(texSampler, vec2(texPos3.x,  texPos12.y), 0) * w3.x * w12.y;

    result += textureLod(texSampler, vec2(texPos0.x,  texPos3.y), 0) * w0.x * w3.y;
    result += textureLod(texSampler, vec2(texPos12.x, texPos3.y), 0) * w12.x * w3.y;
    result += textureLod(texSampler, vec2(texPos3.x,  texPos3.y), 0) * w3.x * w3.y;

    return max(result, 0.0);
}
