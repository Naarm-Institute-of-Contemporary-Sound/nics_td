// Boiler Plate ray marching code
// Author: Ryan Priday
// 15/08/2026


const int MAX_STEPS = 128;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;

// #define TAU 6.28318530718

// uniform vec4 time;

float sdf_box( vec3 p, vec3 b ){
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf_sphere(vec3 pos) {
	return length(pos) - 1.0;
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

float sdf_scene(vec3 p) {
  	// return sdf_sphere(p);
	float s1 = sdf_sphere(vec3(p.x, p.y, p.z));
	float s2 = sdf_sphere(vec3(p.x, p.y, p.z));

	return min(s1, s2);
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

vec3 calcNormal(vec3 p)
{
    const vec2 h = vec2(EPSILON,0);
    return normalize( vec3(sdf_scene(p+h.xyy) - sdf_scene(p-h.xyy),
                           sdf_scene(p+h.yxy) - sdf_scene(p-h.yxy),
                           sdf_scene(p+h.yyx) - sdf_scene(p-h.yyx) ) );
}

vec3 phong(vec3 hitPos, vec3 eye, vec3 lightPos, vec3 lightColor) {
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

	vec3 objectColor = vec3(1.0, 1.0, 1.0);

	return objectColor*(ambient+diffuse)*lightColor+specular*lightColor;
}

out vec4 fragColor;
void main()
{
	vec2 res = uTDOutputInfo.res.zw;

	float fov = 60.0;
	vec3 eye = vec3(0.0, 0.0, 7.0);
	vec3 rayDir = rayDirection(fov, res);

	float depth = march(eye, rayDir);

	vec3 hitPosition = eye+rayDir*depth;

	vec3 normal = calcNormal(hitPosition);

	vec3 color = vec3(.0);

	color = phong(hitPosition, eye, vec3(0, 0, 3),
		vec3(1, 1, 1));

	color = normal;

	float alpha = 1.0;
	if (depth >= MAX_DIST)
	{
		color = vec3(0.);
		alpha = 1.0;
	}

	// color = vec3(0.0, 0.0, 1.0);

	fragColor = TDOutputSwizzle(vec4(color, alpha));

}
