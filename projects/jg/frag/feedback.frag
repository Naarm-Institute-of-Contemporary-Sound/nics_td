
// Example Pixel Shader

// uniform float exampleUniform;

out vec4 fragColor;
void main()
{
    // Coords of current pixel
    vec2 uv = vUV.st;

    // TD inputs
    vec4 px_current     = texture(sTD2DInputs[0], uv); // glsl_generate
    vec4 px_previous    = texture(sTD2DInputs[1], uv); // feedback1

    // Do something!!!
    vec4 colour = mix(px_current, px_previous, 0.95);

	// vec4 color = texture(sTD2DInputs[0], vUV.st);
	// vec4 color = vec4(1.0);
	fragColor = TDOutputSwizzle(colour);
}
