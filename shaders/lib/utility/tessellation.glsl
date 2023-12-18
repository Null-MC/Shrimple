#ifdef RENDER_TESS_CONTROL
    vec3 GetPatchDistances(const in float distMin, const in float distMax) {
        vec3 distances = vec3(
            gl_in[0].gl_Position.z,
            gl_in[1].gl_Position.z,
            gl_in[2].gl_Position.z);

        //return saturate((abs(distances) - MIN_DISTANCE) / (MATERIAL_DISPLACE_MAX_DIST - MIN_DISTANCE));
        return smoothstep(distMin, distMax, abs(distances));
    }

    void ApplyPatchControl(const in vec3 distance, const in float maxQuality) {
        gl_TessLevelOuter[0] = mix(maxQuality, 1.0, max(distance[1], distance[2]));
        gl_TessLevelOuter[1] = mix(maxQuality, 1.0, max(distance[2], distance[0]));
        gl_TessLevelOuter[2] = mix(maxQuality, 1.0, max(distance[0], distance[1]));

        gl_TessLevelInner[0] = mix(maxQuality, 1.0, maxOf(distance));
    }
#endif

#ifdef RENDER_TESS_EVAL
    #define _interpolate(v0, v1, v2) (gl_TessCoord.x * (v0) + gl_TessCoord.y * (v1) + gl_TessCoord.z * (v2))

    #if DISPLACE_MODE == DISPLACE_TESSELATION
        vec3 GetSampleOffset() {
            float strength = ParallaxDepthF;

            #ifdef MATERIAL_TESSELLATION_EDGE_FADE
                float edge = maxOf(2.0 * abs(vOut.localCoord - 0.5));
                strength *= smoothstep(1.0, 0.85, edge);
            #endif

            float depthSample = texture(normals, vOut.texcoord).a;
            float offsetDepthSample = MaterialTessellationOffset - depthSample;
            offsetDepthSample *= step(depthSample, 0.9999);

            return vOut.localNormal * -(offsetDepthSample * strength);
        }
    #endif
#endif
