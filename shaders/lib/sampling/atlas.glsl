#ifdef RENDER_VERTEX
    void GetAtlasBounds(const in vec2 texcoord, out mat2 atlasBounds, out vec2 localCoord) {
        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
        vec2 coordNMid = texcoord - coordMid;// - 0.5/atlasSize;

        atlasBounds[0] = min(texcoord, coordMid - coordNMid);
        atlasBounds[1] = abs(coordNMid) * 2.0;

        localCoord = sign(coordNMid) * 0.5 + 0.5;
    }
#endif

#ifdef RENDER_FRAG
    // atlasBounds: [0]=position [1]=size
    vec2 GetAtlasCoord(const in vec2 localCoord) {
        return fract(localCoord) * vIn.atlasBounds[1] + vIn.atlasBounds[0];
    }

    vec2 GetLocalCoord(const in vec2 atlasCoord) {
        return (atlasCoord - vIn.atlasBounds[0]) / vIn.atlasBounds[1];
    }
#endif
