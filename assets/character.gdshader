shader_type canvas_item;

uniform float shake_power = 0.005; // How far the pixels move
uniform float shake_speed = 20.0;  // How fast they vibrate

// Simple pseudo-random function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Create a time-based seed that changes quickly
    float time_snap = floor(TIME * shake_speed);
    
    // Generate a unique offset for this specific pixel coordinate
    vec2 offset;
    offset.x = random(SCREEN_UV + time_snap) - 0.5;
    offset.y = random(SCREEN_UV + time_snap + 1.0) - 0.5;
    
    // Apply the shake to the UVs
    vec2 shaken_uv = UV + offset * shake_power;
    
    // Output the texture with the new UV
    COLOR = texture(TEXTURE, shaken_uv);
}