shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float dry_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float wet_roughness : hint_range(0.0, 1.0) = 0.05;
uniform float puddle_scale : hint_range(0.1, 10.0) = 2.0;

// Simple procedural noise for puddles
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
    ALBEDO = base_color.rgb;
    
    // Generate puddles based on world position
    vec2 uv = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz * puddle_scale;
    float n = noise(uv);
    n = smoothstep(0.4, 0.6, n); // sharp puddles
    
    // Wet areas are highly reflective (low roughness), dry areas are rough
    ROUGHNESS = mix(dry_roughness, wet_roughness, n);
    METALLIC = 0.1;
    
    // Slight darkening where wet
    ALBEDO *= mix(1.0, 0.5, n);
}
