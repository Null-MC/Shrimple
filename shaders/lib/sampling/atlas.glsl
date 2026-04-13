#ifdef RENDER_VERTEX
//    void GetAtlasBounds(const in vec2 texcoord, out mat2 atlasBounds, out vec2 localCoord) {
//        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
//        vec2 coordNMid = texcoord - coordMid;// - 0.5/atlasSize;
//
//        atlasBounds[0] = min(texcoord, coordMid - coordNMid);
//        atlasBounds[1] = abs(coordNMid) * 2.0;
//
//        localCoord = sign(coordNMid) * 0.5 + 0.5;
//    }

    void GetAtlasBounds(const in vec2 texcoord, out vec2 tilePos, out vec2 tileSize) {
        vec2 coordMid = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
        vec2 coordNMid = texcoord - coordMid;// - 0.5/atlasSize;

        tilePos = min(texcoord, coordMid - coordNMid);
        tileSize = abs(coordNMid) * 2.0;

//        localCoord = sign(coordNMid) * 0.5 + 0.5;
    }
#endif

#ifdef RENDER_FRAGMENT
    vec2 GetAtlasCoord(const in vec2 localCoord, const in vec2 tilePos, const in vec2 tileSize) {
        return fma(fract(localCoord), tileSize, tilePos);
    }

    vec2 GetLocalCoord(const in vec2 atlasCoord, const in vec2 tilePos, const in vec2 tileSize) {
        return saturate((atlasCoord - tilePos) / tileSize);
    }
#endif
