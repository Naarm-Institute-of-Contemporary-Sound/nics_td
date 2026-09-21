// Box visual
// Author: Ryan Priday (Pry)

const int MAX_STEPS = 128;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;

#define TAU 6.28318530718

uniform vec4 time;
float timeVar =  time.x * 1.;
float timeVar2 = time.x * 0.03;
float timeVar3 = time.x * 0.02;

float sdf_box( vec3 p, vec3 b ){
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdf_sphere(vec3 pos) {
	return length(pos) - .4;
}

mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s,
                s,  c);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float smoothDifferenceSDF(float a, float b, float k) {
    return -opSmoothUnion(-a, b, k);
}

float sdf_weirdCube(vec3 pos) {
	vec3 p = pos;

	float t = time.x;
	float angle = t/2;
	p.xz = rot(angle) * p.xz;

	// float cut = differenceSDF(sdf_box(p, vec3(0.5)), sdf_box(vec3(p.x+0.35, p.y+0.35, p.z), vec3(.1, .1, .55)));
	float scene = sdf_box(p, vec3(0.5, 0.5, .55));
	// float scene = sdf_box(p, vec3(0.5, 0.5, .5*2*sin(timeVar3)+0.1));

	// for (int xi = -1; xi <= 1; xi++) {
	//     for (int yj = -1; yj <= 1; yj++) {
	//         float i = float(xi) * 0.3;
	//         float j = float(yj) * 0.3;

	//         float cutter = sdf_box(
	//             p - vec3(i, j, 0.0),
	//             vec3(.03 * 1.2 * (sin(t) + 1.0),
	//                  .03 * 1.2 * (cos(t) + 1.0),
	//                  // 0.5*2*sin(timeVar3)+0.15) // Changes the size of the weird cube
	// 								 0.55) // Changes the size of the weird cube
	//         );

	// 		scene = smoothDifferenceSDF(scene, cutter, 0.04);
	// 	}
	// }

	return opSmoothUnion(1000, scene, .5-(clamp(100, 0.0, 1.0)*0.2));
	// return scene;
	// return sdf_box(p, vec3(0.5));
	// return sdf_sphere(p);
}

// float sdf_scene(vec3 p) {
// 	p.x = fract(p.x);
// 	return sdf_box(p+vec3(.0, .0, .0), vec3(0.5));
// }

float sdf_scene(vec3 p) {
    float d = 50;
    float spread = 3;
    vec3 bp = p;
    bp.z -= 2.0;

    float c02 = cos(timeVar * 0.33);
    float c04 = cos(timeVar * 0.66);
    float blend = sin(time.x * 0.15 + 0.3) * 0.4 + 0.5;

    float depth = 3.0; //iLow*1.2 + 1.2;

		// werid cubes
    for (int i = 0; i < 10; i++) {
        float fi = float(i);
        float si = sin(timeVar + fi * 0.3);
        float co = cos(timeVar2 - fi * 2.5) * 0.5 + cos(0.3 + timeVar2 - fi * 1.3) * 0.5;
        float z = sin(timeVar * 0.8 + fi * 1.7) * depth;
        vec3 off = spread * vec3(
								    si * c04 * 0.9 + c02 * .5,
								    co * 0.88,
								    z * 1.8
								);
        vec3 pp = bp - off;

        float b = sdf_weirdCube(pp);
        //float blendSDF = mix(s, b, blend); // faster than two smooth unions
        d = opSmoothUnion(d, b, 2.-(clamp(3, 0.0, 1.0)*0.2));
    }

    return d;
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

vec3 phong(vec3 hitPos, vec3 eye, vec3 lightPos, vec3 lightcolour) {
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

	vec3 objectcolour = vec3(1.0, 1.0, 1.0);

	return objectcolour*(ambient+diffuse)*lightcolour+specular*lightcolour;
}



out vec4 fragcolour;
void main()
{
	vec2 res = uTDOutputInfo.res.zw;
	float t = time.x;

	float fov = 60.0;
	vec3 eye = vec3(sin(t/5)*3, sin(t/5)*3, 0);
	vec3 rayDir = rayDirection(fov, res);

	// early exit
	float depth = march(eye, rayDir);
	float alpha = 1.0;
	if (depth >= MAX_DIST)
	{
		// colour = vec3(0.);
		alpha = 0.0;
		fragcolour = TDOutputSwizzle(vec4(vec3(0.), alpha));
		return;
	}

	vec3 hitPosition = eye+rayDir*depth;

	vec3 colour1 = phong(hitPosition, eye, vec3(0*sin(t), 0*cos(t), .2*sin(t)),
		vec3(-abs(sin(t))+0.6, 0.5, 1));
	vec3 colour2 = phong(hitPosition, eye, vec3(0*cos(t), 0*sin(t), .2*cos(t)),
		vec3(0.9, -abs(cos(t))+0.6, 1));

	// colour = normal;
	vec3 normal = calcNormal(hitPosition);

	vec3 colour_mixed = mix(colour1, colour2, 0.5);
	// colour_mixed = vec3(0.0, 0.0, 1.0);

	fragcolour = TDOutputSwizzle(vec4(colour_mixed, alpha));
}