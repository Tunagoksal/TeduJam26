shader_type canvas_item;

uniform float progress : hint_range(0, 1);
uniform bool reverse = false;

// Size of each diamond, in pixels.
uniform float diamondPixelSize = 8.0;

void fragment() {
    float xFraction = fract(FRAGCOORD.x / diamondPixelSize);
    float yFraction = fract(FRAGCOORD.y / diamondPixelSize);
    
    float xDistance = abs(xFraction - 0.5);
    float yDistance = abs(yFraction - 0.5);

    if (reverse) {
        // Reverse effect
        if (xDistance + yDistance + UV.x + UV.y <= progress * 4.0) {
            discard;
        }
    } else {
        // Normal effect
        if (xDistance + yDistance + UV.x + UV.y > progress * 4.0) {
            discard;
        }
    }
}
