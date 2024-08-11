shader_type spatial;

uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0); // Outline color
uniform float outline_width = 1.0; // Width of the outline

void fragment() {
    // Calculate normal vector
    vec3 normal = normalize(NORMAL);

    // Compute the edge using the width of the fragment
    float edge = length(fwidth(normal.z));

    // If the edge is less than the outline width, color it
    if (edge < outline_width) {
        ALBEDO = outline_color.rgb;
    } else {
        discard; // Discard pixels that are not on the edge
    }
}
