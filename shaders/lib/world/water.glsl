#define WAVE_ITERATIONS_VERTEX 8
#define WAVE_ITERATIONS_FRAGMENT 16

//const int PHYSICS_ITERATIONS_OFFSET = 13;
const float PHYSICS_TIME_MULTIPLICATOR = 4.0;
const float PHYSICS_XZ_SCALE = 0.12;

const float PHYSICS_W_DETAIL = 0.85;
const float PHYSICS_DRAG_MULT = 0.026;
const float PHYSICS_FREQUENCY = 6.0;
const float PHYSICS_SPEED = 2.0;
const float PHYSICS_WEIGHT = 0.6;
const float PHYSICS_FREQUENCY_MULT = 1.18;
const float PHYSICS_SPEED_MULT = 1.07;
const float PHYSICS_ITER_INC = 12.0;
const float PHYSICS_NORMAL_STRENGTH = 0.5;

const float physics_oceanHeight = 0.3;


float water_waveHeight(const in vec2 worldPos) {
    vec2 position = worldPos * PHYSICS_XZ_SCALE;
    float time = frameTimeCounter / 3.6;

	float iter = 0.0;
    float frequency = PHYSICS_FREQUENCY;
    float speed = PHYSICS_SPEED;
    float weight = 1.0;
    float height = 0.0;
    float waveSum = 0.0;
    float modifiedTime = time * PHYSICS_TIME_MULTIPLICATOR;
    
    for (int i = 0; i < WAVE_ITERATIONS_VERTEX; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, position) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        position -= force * PHYSICS_DRAG_MULT;
        height += wave * weight;
        iter += PHYSICS_ITER_INC;
        waveSum += weight;
        weight *= PHYSICS_WEIGHT;
        frequency *= PHYSICS_FREQUENCY_MULT;
        speed *= PHYSICS_SPEED_MULT;
    }
    
    return height / waveSum * physics_oceanHeight - physics_oceanHeight * 0.5;
}

vec2 water_waveDirection(const in vec2 worldPos, out vec2 uvOffset) {
    float time = frameTimeCounter / 3.6;

    vec2 wavePos = worldPos * PHYSICS_XZ_SCALE;
	float iter = 0.0;
    float frequency = PHYSICS_FREQUENCY;
    float speed = PHYSICS_SPEED;
    float weight = 1.0;
    float waveSum = 0.0;
    float modifiedTime = time * PHYSICS_TIME_MULTIPLICATOR;
    vec2 dx = vec2(0.0);
    
    for (int i = 0; i < WAVE_ITERATIONS_FRAGMENT; i++) {
        vec2 direction = vec2(sin(iter), cos(iter));
        float x = dot(direction, wavePos) * frequency + modifiedTime * speed;
        float wave = exp(sin(x) - 1.0);
        float result = wave * cos(x);
        vec2 force = result * weight * direction;
        
        dx += force / pow(weight, PHYSICS_W_DETAIL); 
        wavePos -= force * PHYSICS_DRAG_MULT;
        iter += PHYSICS_ITER_INC;
        waveSum += weight;
        weight *= PHYSICS_WEIGHT;
        frequency *= PHYSICS_FREQUENCY_MULT;
        speed *= PHYSICS_SPEED_MULT;
    }
    
    uvOffset = (wavePos / PHYSICS_XZ_SCALE) - worldPos;

    return vec2(dx / pow(waveSum, 1.0 - PHYSICS_W_DETAIL));
}

vec3 water_waveNormal(const in vec2 worldPos, out vec2 uvOffset) {
    float totalFactor = physics_oceanHeight / 13.0;
    vec2 wave = -water_waveDirection(worldPos, uvOffset);
    return normalize(vec3(wave.x * totalFactor, PHYSICS_NORMAL_STRENGTH, wave.y * totalFactor));
}
