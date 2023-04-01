float manualDeterminant(const in mat2 matrix) {
    return matrix[0].x * matrix[1].y - matrix[0].y * matrix[1].x;
}

mat2 inverse2(const in mat2 m) {
    mat2 adj;
    adj[0][0] =  m[1][1];
    adj[0][1] = -m[0][1];
    adj[1][0] = -m[1][0];
    adj[1][1] =  m[0][0];
    return adj / manualDeterminant(m);
}

vec4 textureAnisotropic(const in sampler2D sampler, const in vec2 uv) {
    mat2 J = inverse(mat2(dFdx(uv), dFdy(uv)));
    J = transpose(J) * J;     // quadratic form

    float d = manualDeterminant(J), t = J[0][0]+J[1][1],  // find ellipse: eigenvalues, max eigenvector
          D = sqrt(abs(t*t-4.0*d)),                 // abs() fix a bug: in weird view angles 0 can be slightly negative
          V = (t-D)/2.0, v = (t+D)/2.0,                // eigenvalues
          M = 1.0/sqrt(V), m = 1.0/sqrt(v);             // = 1./radii^2

    vec2 A = M * normalize(vec2(-J[0][1], J[0][0]-V)); // max eigenvector = main axis

    float lod;
    if (M/m > 16.0) {
        lod = log2(M / 16.0 * viewHeight);
    } else {
        lod = log2(m * viewHeight);
    }

    const float AnisotropicSamplesInv = rcp(AF_SAMPLES);
    vec2 ADivSamples = A * AnisotropicSamplesInv;

    vec2 spriteDimensions = vec2(spriteBounds.z - spriteBounds.x, spriteBounds.w - spriteBounds.y);

    vec4 final;
    final.rgb = vec3(0.0);

    // preserve original alpha to prevent artifacts
    final.a = textureLod(sampler, uv, lod).a;

    const float samplesDiv2 = AF_SAMPLES / 2.0;
    for (float i = -samplesDiv2 + 0.5; i < samplesDiv2; i++) { // sample along main axis at LOD min-radius
        vec2 sampleUV = uv + ADivSamples * i;
        sampleUV = mod(sampleUV - spriteBounds.xy, spriteDimensions) + spriteBounds.xy; // wrap sample UV to fit inside sprite
        final.rgb += textureLod(sampler, sampleUV, lod).rgb;
    }

    final.rgb *= AnisotropicSamplesInv;
    return final;
}
