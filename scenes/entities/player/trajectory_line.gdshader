shader_type canvas_item;

uniform float distance : hint_range(0.0, 215.0);  // Current distance, clamped between 0 and 215
uniform float soft_max_distance = 180.0;  // Soft max distance (when color starts changing)
uniform float hard_max_distance = 215.0;  // Hard max distance (maximum stretch)
uniform bool is_colliding = false;  // New uniform for collision state

void fragment() {
    // Base colors
    vec4 white = vec4(1.0, 1.0, 1.0, 0.3);      // White color
    vec4 soft_orange = vec4(1.0, 1.0, 1.0, 0.3); // Soft orange
    vec4 hard_orange = vec4(1.0, 0.545, 0.082, 0.7); // Darker orange for hard max
    vec4 collision_color = vec4(1.0, 0.0, 0.0, 0.3); // Red color for collision

    vec4 base_color;
    if (distance < soft_max_distance) {
        base_color = white;
    } else if (distance >= soft_max_distance && distance < hard_max_distance) {
        float t = (distance - soft_max_distance) / (hard_max_distance - soft_max_distance);
        base_color = mix(soft_orange, hard_orange, t);
    } else {
        base_color = hard_orange;
    }
    
    // Mix with collision color if colliding
    COLOR = is_colliding ? collision_color : base_color;
}