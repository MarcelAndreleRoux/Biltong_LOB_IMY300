shader_type canvas_item;

uniform vec4 collision_rect;

void fragment() {
    vec2 uv_pos = FRAGCOORD.xy;  // Get the position of the current fragment

    // Extract the collision rectangle properties
    float left = collision_rect.x;
    float right = collision_rect.x + collision_rect.z;
    float top = collision_rect.y;
    float bottom = collision_rect.y + collision_rect.w;

    // Check if the fragment falls within the collision rect, if so, discard it
    if (uv_pos.x > left && uv_pos.x < right && uv_pos.y > top && uv_pos.y < bottom) {
        discard;
    }

    COLOR = texture(TEXTURE, UV);
}
