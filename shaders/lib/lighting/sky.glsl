#if !defined IRIS_FEATURE_SSBO || defined RENDER_BEGIN
    vec3 sunColor = vec3(1.0);//RGBToLinear(vec3(0.965, 0.901, 0.725));
    vec3 sunColorHorizon = RGBToLinear(vec3(0.813, 0.540, 0.120));
    vec3 moonColorHorizon = 0.06*RGBToLinear(vec3(0.717, 0.708, 0.621));
    vec3 moonColor = 0.06*RGBToLinear(vec3(0.864, 0.860, 0.823));

    vec3 CalculateSkyLightColor(const in vec3 sunDir) {
        vec3 skyLightColor = sunDir.y > 0.0 ? sunColor : moonColor;
        vec3 skyLightHorizonColor = sunDir.y > 0.0 ? sunColorHorizon : moonColorHorizon;

        float horizonF = smoothstep(0.0, 0.7, abs(sunDir.y));
        return mix(skyLightHorizonColor, skyLightColor, horizonF);
        //return skyLightColor * smoothstep(0.0, 0.1, abs(sunDir.y));
    }
#endif

#ifndef RENDER_BEGIN
    vec3 GetSkyLightColor(const in vec3 sunDir) {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            return CalculateSkyLightColor(sunDir);
        #endif
    }

    vec3 GetSkyLightColor() {
        #ifdef IRIS_FEATURE_SSBO
            return WorldSkyLightColor;
        #else
            vec3 localSunDirection = normalize((gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz);
            return CalculateSkyLightColor(localSunDirection);
        #endif
    }
#endif
