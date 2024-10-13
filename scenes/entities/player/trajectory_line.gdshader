shader_type canvas_item;

uniform float distance : hint_range(0.0, 215.0);  // Current distance, clamped between 0 and 215
uniform float soft_max_distance = 180.0;  // Soft max distance (when color starts changing)
uniform float hard_max_distance = 215.0;  // Hard max distance (maximum stretch)

void fragment() {
    // Color interpolation: white at min distance, orange at soft max, deep orange at hard max
    vec4 white = vec4(1.0, 1.0, 1.0, 0.3);      // White color
    vec4 soft_orange = vec4(1.0, 1.0, 1.0, 0.3); // Soft orange
    vec4 hard_orange = vec4(1.0, 0.545, 0.082, 0.7); // Darker orange for hard max

    if (distance < soft_max_distance) {
        COLOR = white;  // White color if under soft max distance
    } else if (distance >= soft_max_distance && distance < hard_max_distance) {
        // Interpolate between soft orange and hard orange
        float t = (distance - soft_max_distance) / (hard_max_distance - soft_max_distance);
        COLOR = mix(soft_orange, hard_orange, t);
    } else {
        COLOR = hard_orange;  // Hard orange if at max distance
    }
}