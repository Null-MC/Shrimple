#ifdef RENDER_VERTEX
    void GetAtlasBounds(const in vec2 texcoord, out mat2 atlasBounds, out vec2 localCoord) {
        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
        vec2 coordNMid = texcoord - coordMid;// - 0.5/atlasSize;

        atlasBounds[0] = min(texcoord, coordMid - coordNMid);
        atlasBounds[1] = abs(coordNMid) * 2.0;

        localCoord = sign(coordNMid) * 0.5 + 0.5;
    }
#else
    // atlasBounds: [0]=position [1]=size
    vec2 GetAtlasCoord(const in vec2 localCoord, const in mat2 atlasBounds) {
        return fract(localCoord) * atlasBounds[1] + atlasBounds[0];
    }

    vec2 GetLocalCoord(const in vec2 atlasCoord, const in mat2 atlasBounds) {
        return (atlasCoord - atlasBounds[0]) / atlasBounds[1];
    }
#endif
