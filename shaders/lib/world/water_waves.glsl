#define WATER_ITERATIONS_VERTEX 8

const float WATER_TIME_MULTIPLICATOR = 4.0;
const float WATER_FREQUENCY = 1.0;
const float WATER_FREQUENCY_MULT = 1.14;
const float WATER_SPEED_MULT = 1.06;
const float WATER_ITER_INC = 0.16 * PI * (3.0 - sqrt(5.0));
const float WATER_WEIGHT = 0.55;
const float WATER_NORMAL_STRENGTH = 0.5;

#if   WORLD_WATER_WAVES == 3
    #define WATER_ITERATIONS_FRAGMENT 42
    const float WATER_XZ_SCALE = 0.4;
    float WATER_DRAG_MULT = 0.3;//mix(0.2, 0.6, rainStrength);
    const float WATER_DRAG_INC = 0.06;
    const float WATER_WAVE_HEIGHT = 0.9;
    const float WATER_SPEED = 1.4;
#elif WORLD_WATER_WAVES == 2
    #define WATER_ITERATIONS_FRAGMENT 32
    const float WATER_XZ_SCALE = 0.8;
    float WATER_DRAG_MULT = 0.3;//mix(0.2, 0.4, rainStrength);
    const float WATER_DRAG_INC = 0.06;
    const float WATER_WAVE_HEIGHT = 0.5;
    const float WATER_SPEED = 2.0;
#elif WORLD_WATER_WAVES == 1
    #define WATER_ITERATIONS_FRAGMENT 18
    const float WATER_XZ_SCALE = 1.6;
    const float WATER_DRAG_MULT = 0.3;
    const float WATER_DRAG_INC = 0.8;
    const float WATER_WAVE_HEIGHT = 0.25;
    const float WATER_SPEED = 2.6;
#endif


float water_waveHeight(const in vec2 worldPos, const in float skyLight) {
    //float time = frameTimeCounter;
    float modifiedTime = GetAnimationFactor() / 3.6;
    modifiedTime *= WATER_TIME_MULTIPLICATOR;

    vec2 position = worldPos * WATER_XZ_SCALE;
    float lightF = mix(skyLight, 1.0, WATER_WAVE_MIN);

	float iter = 0.0;
    float frequency = WATER_FREQUENCY;
    float speed = WATER_SPEED;
    float weight = lightF;
    float height = 0.0;
    float waveSum = 0.0;
    float drag = WATER_DRAG_MULT;
    
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
        drag *= WATER_DRAG_INC;
    }
    
    if (waveSum < EPSILON) return 0.0;
    return ((height / waveSum) - 0.8 * step(EPSILON, lightF)) * WATER_WAVE_HEIGHT * lightF;
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
    float drag = WATER_DRAG_MULT;
    vec2 dx = vec2(0.0);
    
    for (int i = 0; i < WATER_ITERATIONS_FRAGMENT; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, wavePos) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        dx += force / pow(weight, detailF); 
        wavePos -= force * drag;
        iter += WATER_ITER_INC;
        waveSum += weight;
        weight *= WATER_WEIGHT;
        frequency *= WATER_FREQUENCY_MULT;
        speed *= WATER_SPEED_MULT;
        drag *= WATER_DRAG_INC;
    }
    
    uvOffset = (wavePos / WATER_XZ_SCALE) - worldPos;

    if (waveSum < EPSILON) return vec2(0.0);
    return dx / waveSum * lightF;//pow(waveSum, 1.0 - detailF));
}

vec3 water_waveNormal(vec2 worldPos, const in float skyLight, const in float viewDist, out vec2 uvOffset) {
    #if WORLD_WATER_PIXEL > 0
        worldPos = floor(worldPos * WORLD_WATER_PIXEL) / WORLD_WATER_PIXEL;
    #endif

    float totalFactor = WATER_WAVE_HEIGHT;
    vec2 wave = -water_waveDirection(worldPos, skyLight, uvOffset);
    vec3 normal = vec3(wave * vec2(WATER_WAVE_HEIGHT), rcp(WATER_NORMAL_STRENGTH));

    normal = normalize(normal);

    float strength = 16.0 / (viewDist + 16.0);
    normal = mix(vec3(0.0, 0.0, 1.0), normal, strength);

    return normalize(normal);
}
