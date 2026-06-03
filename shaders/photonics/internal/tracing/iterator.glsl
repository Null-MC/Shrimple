#include "/photonics/palette.glsl"
#include "/photonics/utility/normal_encoding.glsl"

#include "/photonics/internal/tracing/common.glsl"

#define PH_RAY_STATE_READY 0
#define PH_RAY_STATE_HAS_HIT 1
#define PH_RAY_STATE_HAS_MISS 2
#define PH_RAY_STATE_OUT_OF_BOUNDS 3

#define PH_RAY_DEFAULT_ITERATIONS 100
const float ph_16_rcp = 1.0f / 16.0f;

struct RayIterator {
    vec3 position;
    vec3 direction;
    int iterations;

    RayResult hit;
    int state; // this could improved, do I care? no
};

void _ray_iter_setup(inout RayIterator ray) {
    vec3 dir_inv = 1.0f / ray.direction;
    float t0 = ph_intersects_world(dir_inv, ray.position);
    if (t0 == -1) {
        ray.state = PH_RAY_STATE_OUT_OF_BOUNDS;
        return;
    }

    ray.position+= (t0 + 0.03f) * ray.direction;
    ray.state = PH_RAY_STATE_READY;
}

void ray_iter_begin(out RayIterator ray, vec3 position, vec3 direction) {
    ray.position = position;
    ray.direction = direction;

    _ray_iter_setup(ray);
    ray.iterations = PH_RAY_DEFAULT_ITERATIONS;
}

void ray_iter_set_position(inout RayIterator ray, vec3 position) {
    ray.position = position;
}

void ray_iter_offset_position(inout RayIterator ray, vec3 offset) {
    ray.position+= offset;
}

void ray_iter_set_direction(inout RayIterator ray, vec3 direction) {
    ray.direction = direction;
    _ray_iter_setup(ray);
}

const vec3 ph_ray_no_target = vec3(-1.0f);
void _ray_iter_trace_next(inout RayIterator ray, vec3 target) {
    if (ray.state != PH_RAY_STATE_READY) return;
    if (ray.iterations == 0) return;

    uint[11] stack = uint[11](0);
    int scale_exp = 21;

    uint node_index = 0;
    RtNode node = load_rt_node(node_index);

//    uint mirror_mask = 0u;
//    if (ray.direction.x > 0) mirror_mask |= 3u << 0;
//    if (ray.direction.y > 0) mirror_mask |= 3u << 4;
//    if (ray.direction.z > 0) mirror_mask |= 3u << 2;

    uvec3 is_pos = uvec3(greaterThan(ray.direction, vec3(0.0)));
    uint mirror_mask = (is_pos.x * 3u) | (is_pos.y * 48u) | (is_pos.z * 12u);

    vec3 origin = ph_to_norm_pos(ray.position, ray.direction);

    vec3 pos = origin;
    vec3 dir_inv = 1.0f / -abs(ray.direction);

    if (target != ph_ray_no_target) {
        target = ph_to_norm_pos(target, ray.direction);
        target = ph_floor_scale(target, world_block_scale_exp);
    }

    int tmin;
    uint child_index;

    ray.state = PH_RAY_STATE_HAS_MISS;
    ray.hit = ph_ray_miss;

    bool hit_target = false;
    for (; ray.iterations > 0; ray.iterations--) {
        child_index = ph_get_node_cell_index(pos, scale_exp) ^ mirror_mask;

        for (int i = 0; i < 11; i++) {
            if (rt_node_is_leaf(node) || !rt_node_has_child(node, child_index)) break;

            stack[scale_exp >> 1] = node_index;
            node_index = rt_node_get_child(node, child_index, scale_exp);

            if (scale_exp == world_block_scale_exp && ph_is_target(pos, target)) {
                stack[(scale_exp - 2) >> 1] = node_index;

                hit_target = true;
                break;
            }

            node = load_rt_node(node_index);

            scale_exp-= 2;
            child_index = ph_get_node_cell_index(pos, scale_exp) ^ mirror_mask;
        }

        if (hit_target || (rt_node_is_leaf(node) && rt_node_has_child(node, child_index))) {
            ray.state = PH_RAY_STATE_HAS_HIT;
            break;
        }

        int adv_scale_exp = scale_exp;

        const uint64_t zero_64 = uint64_t(0);
        const uint64_t index_mask_64 = uint64_t(0x00330033u);
        if (((node.child_mask >> (child_index & 42u)) & index_mask_64) == zero_64) adv_scale_exp++;

        vec3 cell_min = ph_floor_scale(pos, adv_scale_exp);
        vec3 side_dist = (cell_min - origin) * dir_inv;

        tmin = side_dist.x < side_dist.y ? 0 : 1;
        tmin = side_dist.z < side_dist[tmin] ? 2 : tmin;

        ivec3 neighbor_max = floatBitsToInt(cell_min) + ivec3(
            side_dist.x == side_dist[tmin] ? -1 : (1 << adv_scale_exp) - 1,
            side_dist.y == side_dist[tmin] ? -1 : (1 << adv_scale_exp) - 1,
            side_dist.z == side_dist[tmin] ? -1 : (1 << adv_scale_exp) - 1
        );

        pos = min(origin - (abs(ray.direction) * side_dist[tmin]), intBitsToFloat(neighbor_max));

        uvec3 diff_pos = floatBitsToUint(pos) ^ floatBitsToUint(cell_min);
        int diff_exp = findMSB((diff_pos.x | diff_pos.y | diff_pos.z) & 0xFFAAAAAAu);

        if (diff_exp > scale_exp) {
            scale_exp = diff_exp;
            if (diff_exp > 21) {
                ray.state = PH_RAY_STATE_OUT_OF_BOUNDS;
                break;
            }

            node_index = stack[scale_exp >> 1];
            node = load_rt_node(node_index);
        }
    }

    pos = ph_get_mirrored_pos(pos, ray.direction, false);
    ray.position = (pos - 1.0f) * world_tree_size;

    if (ray.state == PH_RAY_STATE_HAS_HIT) {
        uint palette_entry;
        bool transparent;

        if (!hit_target) {
            LeafNode leaf = load_leaf_node(node, child_index);

            palette_entry = leaf_node_palette_entry(leaf);
            transparent = leaf_node_is_transparent(leaf);
        } else {
            palette_entry = 0u;
            transparent = false;
        }

        vec3 normal = vec3(0.0f);
        normal[tmin] = -sign(ray.direction[tmin]);

        uint child_pos = stack[(world_block_scale_exp - 2) >> 1];

        ray.hit = new_ray_result(
            ray.position,
            ph_encode_voxel_normal(normal),
            palette_entry,
            ph_world_buffer[child_pos + 3],
            ph_world_buffer[child_pos + 4],
            transparent
        );
    }
}

bool ray_iter_has_next(inout RayIterator ray) {
    _ray_iter_trace_next(ray, ph_ray_no_target);
    return ray.state == PH_RAY_STATE_HAS_HIT;
}

RayResult ray_iter_next(inout RayIterator ray) {
    _ray_iter_trace_next(ray, ph_ray_no_target);
    if (ray.state != PH_RAY_STATE_OUT_OF_BOUNDS)
        ray.state = PH_RAY_STATE_READY;

    return ray.hit;
}

bool ray_iter_has_next_block(inout RayIterator ray, vec3 target) {
    _ray_iter_trace_next(ray, target);
    return ray.state == PH_RAY_STATE_HAS_HIT;
}

RayResult ray_iter_next_block(inout RayIterator ray, vec3 target) {
    _ray_iter_trace_next(ray, target);
    if (ray.state != PH_RAY_STATE_OUT_OF_BOUNDS)
    ray.state = PH_RAY_STATE_READY;

    return ray.hit;
}


void _ray_iter_skip_unit(inout RayIterator ray, float scale) {
    vec3 pos = ray.position * scale;

    vec3 intersection = floor(pos) + step(0.0f, ray.direction);
    vec3 t = (intersection - pos) * (1.0f / ray.direction);

    float tmax = min(min(t.x, t.y), t.z) + (0.01f * scale);
    pos+= tmax * ray.direction;

    ray.position = pos / scale;
}

void ray_iter_skip_block(inout RayIterator ray) {
    _ray_iter_skip_unit(ray, 1.0f);
}

void ray_iter_skip_voxel(inout RayIterator ray) {
    _ray_iter_skip_unit(ray, 16.0f);
}

bool ray_iter_is_in_bounds(RayIterator ray) {
    return ray.state != PH_RAY_STATE_OUT_OF_BOUNDS;
}

void ray_iter_apply_transparency(inout vec4 accumulator, vec4 albedo) {
    if (accumulator.a != 0) {
        float mix_factor = (1 - accumulator.a) * albedo.a;
        accumulator.rgb = mix(accumulator.rgb, albedo.rgb, mix_factor);
        accumulator.a+= mix_factor;
    } else accumulator = albedo;
}
