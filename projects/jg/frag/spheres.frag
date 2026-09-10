// Boiler Plate ray marching code
// Author: Ryan Priday
// 15/08/2026


const int MAX_STEPS 	= 128;
const float MAX_DIST 	= 100.0;
const float EPSILON 	= 0.001;
const float TAU 		= 6.28318530718;

const vec3 BLACK 	= vec3(0, 0, 0);
const vec3 WHITE 	= vec3(1, 1, 1);
const vec3 RED 		= vec3(1, 0, 0);
const vec3 GREEN 	= vec3(0, 1, 0);
const vec3 BLUE 	= vec3(0, 0, 1);
const vec3 ORANGE 	= vec3(1, 0.5, 0);


// Vars from TD
uniform vec4 time;
// float time_frame = time.x;
// float time_frame = mod(time.x, 100);
float time_abs = time.y;
// float time_sin = sin(time_abs);

float sdf_box( vec3 p, vec3 b ){
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf_sphere(vec3 pos, float size) {
	return length(pos) - size;
}

// Rotating function
mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s,
                s,  c);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

// Smoothing union function
float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float smoothDifferenceSDF(float a, float b, float k) {
    return -opSmoothUnion(-a, b, k);
}

vec3 space_warp(vec3 p, float offset, float scale) {
	return vec3(
		p.xyz + (
			sin(p.yzx * scale + offset) / scale
		)
	);
}

float sdf_scene(vec3 p) {
	// ONE BALL
  	// return sdf_sphere(p);

	// TWO BALLS
	// float s1 = sdf_sphere(vec3(p.x+1.5, p.y, p.z));
	// float s2 = sdf_sphere(vec3(p.x-1.5, p.y, p.z));
	// return min(s1, s2);


	// ROTATE
	float offset 			= mod(time_abs * 0.3, TAU);
	// p.xz 					= rot(p.xz, offset);

	// SPACE WARP
	int warp_iterations 	= 3;
	float scale 			= 2;
	for (int i = 0; i < warp_iterations; i++) {
		p = space_warp(p, offset, scale);
	}
  	return sdf_sphere(p,
		1
		// 2 + sin(time_abs * 1.5)
	);

	// // MOVING BALL
  	// return sdf_sphere(
	// 	vec3(
	// 		// p.x,
	// 		p.x + sin(time_abs * .9), // smooth!
	// 		// p.y,
	// 		p.y + cos(time_abs * .8), // smooth!
	// 		// p.z
	// 		p.z + 3 // Avoid dipping below surface
	// 	),
	// 	// size
	// 	2 + sin(time_abs * 1.5)
	// );

}

vec3 rayDirection(float fov, vec2 resolution) {
	vec2 xy = gl_FragCoord.xy-resolution/2.0;
	float z = resolution.y/tan(radians(fov)/2.0);
	return normalize(vec3(xy, -z));
}

float march(vec3 eye, vec3 rayDir) {
	float depth = 0.0;

	for (int i = 0; i < MAX_STEPS; i++) {
		float dist = sdf_scene(eye+depth*rayDir);
		if (dist < EPSILON) return depth; // We hit something!
		depth += dist; // Meat and potatoes
		if (depth > MAX_DIST) break;
	}

	return MAX_DIST;
}

vec3 calcNormal(vec3 p) {
    const vec2 h = vec2(EPSILON, 0);
    return normalize( vec3(sdf_scene(p+h.xyy) - sdf_scene(p-h.xyy),
                           sdf_scene(p+h.yxy) - sdf_scene(p-h.yxy),
                           sdf_scene(p+h.yyx) - sdf_scene(p-h.yyx) ) );
}

vec3 phong(vec3 eye, vec3 hitPos, vec3 lightPos, vec3 lightcolour) {
	vec3 normal = calcNormal(hitPos);
	vec3 lightDir = normalize(lightPos-hitPos);
	vec3 viewDir = normalize(eye-hitPos);
	vec3 reflectDir = reflect(-lightDir, normal);

	// background light bouncing off stuff around it etc.
	float ambient = 0.1;

	// overall direct light
	float diffuse = max(dot(normal, lightDir), 0.0);

	// Geordie
	float specular = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

	vec3 objectcolour = WHITE;

	return objectcolour*(ambient+diffuse)*lightcolour+specular*lightcolour;
}

out vec4 fragcolour;
void main()
{
	// boilerplate
	vec2 res 		= uTDOutputInfo.res.zw;
	float fov 		= 60.0;
	vec3 eye 		= vec3(0.0, 0.0, 7.0);

	vec3 ray_dir 	= rayDirection(fov, res);
	float depth 	= march(eye, ray_dir);
	vec3 hit_pos	= eye + ray_dir * depth;

	// Simple
	// vec3 colour = GREEN;
	// vec3 colour = calcNormal(hit_pos);

	// Phong
	// vec3 light_pos = vec3(3, 4, 4); // bit far away
	// vec3 light_pos = vec3(0.5, 5, 3);
	vec3 light_pos = vec3(
		sin(time_abs*1.2) * 5,
		4 + sin(time_abs*.95) * 2,
		3
	);
	// vec3 light_colour	= ORANGE;
	// vec3 light_colour	= BLUE;
	// vec3 light_colour	= vec3(1, sin(time_abs), 0);
	vec3 light_colour	= vec3(
		// 1,
		cos(time_abs),
		sin(time_abs),
		0.5
		// sin(time_abs),
		// tan(time_abs)
	);
	vec3 colour 		= phong(eye, hit_pos, light_pos, light_colour);

	// No hits --> black
	float alpha = 1.0;
	if (depth >= MAX_DIST)
	{
		colour = BLACK;
		alpha = 0.0;
	}

	fragcolour = TDOutputSwizzle(vec4(colour, alpha));
}
