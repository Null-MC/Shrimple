#define WATER_ITERATIONS_VERTEX 8
#define WATER_ITERATIONS_FRAGMENT 24

const float WATER_TIME_MULTIPLICATOR = 4.0;
const float WATER_XZ_SCALE = 0.12;

const float WATER_DETAIL = 1.0;
const float WATER_DRAG_MULT = 0.042;
const float WATER_FREQUENCY = 6.0;
const float WATER_SPEED = 2.0;
const float WATER_WEIGHT = 0.6;
const float WATER_FREQUENCY_MULT = 1.18;
const float WATER_SPEED_MULT = 1.07;
const float WATER_ITER_INC = 5.06711056;
const float WATER_NORMAL_STRENGTH = 0.25;
const float WATER_WAVE_HEIGHT = 0.4;


float water_waveHeight(const in vec2 worldPos, const in float skyLight) {
    vec2 position = worldPos * WATER_XZ_SCALE;
    float time = frameTimeCounter / 3.6;
    float modifiedTime = time * WATER_TIME_MULTIPLICATOR;

	float iter = 0.0;
    float frequency = WATER_FREQUENCY;
    float speed = WATER_SPEED;
    float weight = skyLight;
    float height = 0.0;
    float waveSum = 0.0;
    
    for (int i = 0; i < WATER_ITERATIONS_VERTEX; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        position -= force * WATER_DRAG_MULT;
        height += wave * weight;
        iter += WATER_ITER_INC;
        waveSum += weight;
        weight *= WATER_WEIGHT;
        frequency *= WATER_FREQUENCY_MULT;
        speed *= WATER_SPEED_MULT;
    }
    
    if (waveSum < EPSILON) return 0.0;
    return ((height / waveSum) - 0.6 * step(EPSILON, skyLight)) * WATER_WAVE_HEIGHT * skyLight;
}

vec2 water_waveDirection(const in vec2 worldPos, const in float skyLight, out vec2 uvOffset) {
    float time = frameTimeCounter / 3.6;
    float modifiedTime = time * WATER_TIME_MULTIPLICATOR;

    vec2 wavePos = worldPos * WATER_XZ_SCALE;
	float iter = 0.0;
    float frequency = WATER_FREQUENCY;
    float speed = WATER_SPEED;
    float weight = skyLight;
    float waveSum = 0.0;
    vec2 dx = vec2(0.0);
    
    for (int i = 0; i < WATER_ITERATIONS_FRAGMENT; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, wavePos) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        dx += force / pow(weight, WATER_DETAIL); 
        wavePos -= force * WATER_DRAG_MULT;
        iter += WATER_ITER_INC;
        waveSum += weight;
        weight *= WATER_WEIGHT;
        frequency *= WATER_FREQUENCY_MULT;
        speed *= WATER_SPEED_MULT;
    }
    
    uvOffset = (wavePos / WATER_XZ_SCALE) - worldPos;

    if (waveSum < EPSILON) return vec2(0.0);
    return vec2(dx / pow(waveSum, 1.0 - WATER_DETAIL));
}

vec3 water_waveNormal(vec2 worldPos, const in float skyLight, out vec2 uvOffset) {
    #if WORLD_WATER_PIXEL > 0
        worldPos = floor(worldPos * WORLD_WATER_PIXEL) / WORLD_WATER_PIXEL;
    #endif

    float totalFactor = WATER_WAVE_HEIGHT / 13.0;
    vec2 wave = -water_waveDirection(worldPos, skyLight, uvOffset);
    return normalize(vec3(wave.x * totalFactor, wave.y * totalFactor, WATER_NORMAL_STRENGTH));
}
