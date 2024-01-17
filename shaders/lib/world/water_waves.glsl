#define WATER_ITERATIONS_VERTEX 24

const float WATER_TIME_MULTIPLICATOR = 4.0;
const float WATER_FREQUENCY = 1.0;
const float WATER_FREQUENCY_MULT = 1.14;
const float WATER_SPEED_MULT = 1.06;
const float WATER_ITER_INC = 0.16 * PI * (3.0 - sqrt(5.0));
const float WATER_WEIGHT = 0.8;
const float WATER_NORMAL_STRENGTH = 0.2;
const float WATER_DRAG_MULT = 0.4;

#if   WATER_WAVE_SIZE == 3
    #define WATER_ITERATIONS_FRAGMENT 42
    const float WATER_WAVE_HEIGHT = 0.90;
    const float WATER_XZ_SCALE = 0.6;
    const float WATER_DRAG = 0.65;//mix(0.2, 0.6, skyRainStrength);
    const float WATER_SPEED = 1.4;
#elif WATER_WAVE_SIZE == 2
    const float WATER_WAVE_HEIGHT = 0.45;
    #define WATER_ITERATIONS_FRAGMENT 32
    const float WATER_XZ_SCALE = 1.0;
    const float WATER_DRAG = 0.50;//mix(0.2, 0.4, skyRainStrength);
    const float WATER_SPEED = 2.0;
#elif WATER_WAVE_SIZE == 1
    const float WATER_WAVE_HEIGHT = 0.25;
    #define WATER_ITERATIONS_FRAGMENT 24
    const float WATER_XZ_SCALE = 2.0;
    const float WATER_DRAG = 0.40;
    const float WATER_SPEED = 2.6;
#endif


float water_waveHeight(const in vec2 worldPos, const in float skyLight, const in float time, out vec2 uvOffset) {
    //float time = frameTimeCounter;
    // float modifiedTime = GetAnimationFactor();
    float modifiedTime = time / 3.6 * WATER_TIME_MULTIPLICATOR;

    vec2 position = worldPos * WATER_XZ_SCALE;
    float lightF = mix(skyLight, 1.0, WATER_WAVE_MIN);

	float iter = 0.0;
    float frequency = WATER_FREQUENCY;
    float speed = WATER_SPEED;
    float weight = lightF;
    float height = 0.0;
    float waveSum = 0.0;
    float drag = WATER_DRAG;
    
    for (int i = 0; i < WATER_ITERATIONS_VERTEX; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        position -= force * drag;
        height += wave * weight;
        iter += WATER_ITER_INC;
        waveSum += weight;
        weight *= WATER_WEIGHT;
        frequency *= WATER_FREQUENCY_MULT;
        speed *= WATER_SPEED_MULT;
        drag *= WATER_DRAG_MULT;
        //drag = 1.0 - (1.0 - drag) * WATER_DRAG_MULT;
    }
    
    uvOffset = (position / WATER_XZ_SCALE) - worldPos;
    
    if (waveSum < EPSILON) return 0.0;
    return ((height / waveSum) - 0.8 * lightF) * WATER_WAVE_HEIGHT * lightF * 1.6;
}

vec2 water_waveDirection(const in vec2 worldPos, const in float skyLight, out vec2 uvOffset) {
    float modifiedTime = GetAnimationFactor() / 3.6;
    modifiedTime *= WATER_TIME_MULTIPLICATOR;

    float lightF = mix(skyLight, 1.0, WATER_WAVE_MIN);
    float detailF = mix(0.80, 0.95, lightF);//0.7 + 0.2 * lightF;

    vec2 wavePos = worldPos * WATER_XZ_SCALE;
	float iter = 0.0;
    float frequency = WATER_FREQUENCY;
    float speed = WATER_SPEED;
    float weight = lightF;
    float waveSum = 0.0;
    float drag = WATER_DRAG;
    vec2 dx = vec2(0.0);
    
    for (int i = 0; i < WATER_ITERATIONS_FRAGMENT; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, wavePos) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        dx -= force / pow(weight, detailF); 
        wavePos -= force * drag;
        iter += WATER_ITER_INC;
        waveSum += weight;
        weight *= WATER_WEIGHT;
        frequency *= WATER_FREQUENCY_MULT;
        speed *= WATER_SPEED_MULT;
        drag *= WATER_DRAG_MULT;
        //drag = 1.0 - (1.0 - drag) * WATER_DRAG_MULT;
    }
    
    uvOffset = (wavePos / WATER_XZ_SCALE) - worldPos;

    if (waveSum < EPSILON) return vec2(0.0);
    return (dx / waveSum) * 2.0 * lightF;//pow(waveSum, 1.0 - detailF));
}

vec3 water_waveNormal(vec2 worldPos, const in float skyLight, const in float viewDist, out vec2 uvOffset) {
    #if WATER_SURFACE_PIXEL_RES > 0
        worldPos = floor(worldPos * WATER_SURFACE_PIXEL_RES) / WATER_SURFACE_PIXEL_RES;
    #endif

    //float totalFactor = WATER_WAVE_HEIGHT;
    vec2 wave = water_waveDirection(worldPos, skyLight, uvOffset);
    vec3 normal = vec3(wave * WATER_WAVE_HEIGHT, rcp(WATER_NORMAL_STRENGTH));

    normal = normalize(normal);

    float strength = 16.0 / (0.2*viewDist + 16.0);
    //float strength = smoothstep(0.0, 160.0, viewDist);
    // float strength = min(viewDist / 800.0, 1.0);
    normal = mix(vec3(0.0, 0.0, 1.0), normal, strength);
    normal = normalize(normal);

    return normal;
}
