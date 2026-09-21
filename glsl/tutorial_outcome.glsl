layout(location = 0) out vec4 fragColor;

const int MAX_STEPS = 128;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;

uniform vec4 time;

// length = √(x² + y² + z²)
// (0 2 0) -> 1
// (0 .5 0) -> -.5
// (2, 1, 3) -> 3.0230812
float sdf_sphere(vec3 pos) {
	return length(pos) - .4;
}

float sdf_scene(vec3 pos) {
	vec3 p = pos;

	p.x = fract(p.x);
	p.y = fract(p.y);

	return sdf_sphere(p-vec3(.5, .5, .0));
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

vec3 calcNormal(vec3 p) // for function f(p)
{
    const vec2 h = vec2(EPSILON,0);
    return normalize( vec3(sdf_scene(p+h.xyy) - sdf_scene(p-h.xyy),
                           sdf_scene(p+h.yxy) - sdf_scene(p-h.yxy),
                           sdf_scene(p+h.yyx) - sdf_scene(p-h.yyx) ) );
}

vec3 phong(vec3 hitPos, vec3 eye, vec3 lightPos) {
	vec3 normal = calcNormal(hitPos);
	vec3 lightDir = normalize(lightPos-hitPos);
	vec3 viewDir = normalize(eye-hitPos);
	vec3 reflectDir = reflect(-lightDir, normal);

	// background light bouncing off stuff around it etc.
	float ambient = 0.1;

	// overall direct light
	float diffuse = max(dot(normal, lightDir), 0.0);

	// geordie
	float specular = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

	vec3 objectColor = vec3(1.0, 1.0, 1.0);
	vec3 lightColor = vec3(1.0);

	return objectColor*(ambient+diffuse)*lightColor+specular*lightColor;
}

// :^)
void main() {
	vec2 res = uTDOutputInfo.res.zw;

	float t = time.x;

	float fov = 60.0;
	vec3 eye = vec3(0.0, 0.0, 10.0);
	vec3 rayDir = rayDirection(fov, res);

	float depth = march(eye, rayDir);

	vec3 hitPosition = eye+rayDir*depth;

	vec3 normal = calcNormal(hitPosition);

	vec3 color = vec3(.0);

	color = phong(hitPosition, eye, vec3(sin(t*.01)*5.-6.5, 5.0, cos(t*.02)*4.));
	color += phong(hitPosition, eye, vec3(2., 2., 2.));

	if (depth >= MAX_DIST)
		color = vec3(0.);


	fragColor = TDOutputSwizzle(vec4(color, 1.0));
}