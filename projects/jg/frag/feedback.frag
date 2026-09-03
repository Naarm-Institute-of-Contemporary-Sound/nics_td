
// Example Pixel Shader

// uniform float exampleUniform;

out vec4 fragColor;
void main()
{
    // Coords of current pixel
    vec2 uv = vUV.st;


    // Get pixels
    vec4 px_current     = texture(sTD2DInputs[0], uv); // glsl_generate
    // vec4 px_previous    = texture(sTD2DInputs[1], uv); // feedback1
    vec4 px_previous    = texture(sTD2DInputs[1], uv_offset); // feedback1


    // revert coords to (0,0) --> offset --> correct
    float offset    = 0.95;
    vec2 uv_offset  = (uv - 0.5) * offset + 0.5;


    // basic blur
    vec4 colour = mix(px_current, px_previous, 0.7);

    // ignore feedback, if foreground
    if (px_current.a > 0.5) { // currently just 0 or 1 from glsl_generate
        colour = px_current;
    }

	fragColor = TDOutputSwizzle(colour);
}
