shader_type canvas_item;

uniform bool should_be_blue = false;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Check if the pixel is any shade of red
    if (texture_color.r > texture_color.b && texture_color.r > texture_color.g) {
        if (should_be_blue) {
            float intensity = texture_color.r;
            // Increase brightness by scaling up intensity
            intensity = min(intensity * 1.2, 1.0);  // Increase 1.5 for brighter, decrease for darker
            
            // Convert to the specific blue color with increased brightness
            float r = (79.0/255.0) * intensity;
            float g = (143.0/255.0) * intensity;
            float b = (186.0/255.0) * intensity;
            texture_color = vec4(r, g, b, texture_color.a);
        }
    }
    
    COLOR = texture_color;
}