vec3 GetWorldCurvedPosition(in vec3 position) {
    position.y += WORLD_RADIUS;
    position = normalize(position) * position.y;
    position.y -= WORLD_RADIUS;

    return position;
}
