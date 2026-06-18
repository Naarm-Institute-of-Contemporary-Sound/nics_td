/*
 * DAY 15 - fractal crack
 * I compressed this down into a 4k demoscene demo with a renoise tracker track but
 * never got around to submitting it anywhere :(
 * by @auricular
 * 19/05/2025 :)
 */

// uniform float exampleUniform;

// Add a global uniform variable
float blendFactor = 1.0;
uniform float time;

// uniform TDTexInfo uTDOutputInfo;

#define PI 3.1415926535897932384626433832795
#define TAU 6.2831853071795864769252867665590

vec2 uResolution = uTDOutputInfo.res.zw;


out vec4 fragColor;
float sphereSDF(vec3 p, float r) {
	return length(p) - r;
}

mat3 lookAt(vec3 eye, vec3 target, vec3 up) {
	vec3 zAxis = normalize(target - eye); // Forward vector
	vec3 xAxis = normalize(cross(up, zAxis)); // Right vector
	vec3 yAxis = cross(zAxis, xAxis); // Up vector

	return mat3(xAxis, yAxis, zAxis);
}

vec3 rotate_y_x_point(vec3 pt, float x, float y) {
	mat4 Rx = mat4(
	vec4(1, 0, 0, 0),
	vec4(0, cos(x), -sin(x), 0),
	vec4(0, sin(x), cos(x), 0),
	vec4(0, 0, 0, 1));

	mat4 Ry = mat4(
	vec4(cos(y), 0, sin(y), 0),
	vec4(0, 1, 0, 0),
	vec4(-sin(y), 0, cos(y), 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Ry*Rx);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}

vec3 rotate_y_point(vec3 pt, float y) {
	mat4 Ry = mat4(
	vec4(cos(y), 0, sin(y), 0),
	vec4(0, 1, 0, 0),
	vec4(-sin(y), 0, cos(y), 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Ry);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}
vec3 rotate_z_point(vec3 pt, float z) {
    mat4 Rz = mat4(
        vec4( cos(z), -sin(z), 0, 0),
        vec4( sin(z),  cos(z), 0, 0),
        vec4(      0,       0, 1, 0),
        vec4(      0,       0, 0, 1)
    );
    mat4 inv = inverse(Rz);
    return (vec4(pt,1) * inv).xyz;
}

vec3 rotate_x_point(vec3 pt, float x) {
	mat4 Rx = mat4(
	vec4(1, 0, 0, 0),
	vec4(0, cos(x), -sin(x), 0),
	vec4(0, sin(x), cos(x), 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Rx);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}

float sdf_torus(vec3 pos, vec3 xyz, vec2 t) {
	vec2 q = vec2(length(xyz.xy - pos.xy) - t.x, xyz.z - pos.z);
	return length(q) - t.y;
}


float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdPlane( vec3 p, vec3 n, float h ) {
  // n must be normalized
  return dot(p,n) + h;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}



float lTime = 3.0;
float pathSize = 2.; // Varying path size for randomness



const int maxSteps = 512;
const float maxDist = 32.0;
const float minDist = 0.001;



float gyroid(vec3 p, float scale, float bias, float thickness)
{
	p *= scale;
	float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
	return d/scale;
}

float zoff = mod(time*3.0, 2048.0);

vec3 scene(vec3 p) {



	float sc = 4.;
	p.x += sc/2.;
	p.z += zoff;

	p = p - sc*round(p/sc);

	// p.z += zoff;

   float d = sdBox(p,vec3(1.0));
   vec3 res = vec3(d, 1.0, 0.0);

   float s = 1.0;

    for (int i = 0; i < 10; i++) {

        p = abs(p);


        p -= vec3(0.12, 0.7, cos(1.*2.34)*0.2+.3);

		p = rotate_y_x_point(p, 34. * 0.2, cos(2.*.95)); // rotate point

		// p += vec3(hash(p.xy), hash(p.xy), hash(p.zx)) * 0.0001;
		// p *= 0.97;
        // Scale: Zoom in
        // p *= scale;


        float sphereD = sphereSDF(p, 0.9 / pow(s, float(i)));
		// // float torusD = sdf_torus(p, vec3(0.0, 0.0, 0.0), vec2(0.5, 0.04) / pow(s, float(i)));
		float boxD = sdBox(p, vec3(0.5, 0.5, 0.5) / pow(s, float(i)));

        // d = min(d, mix(boxD, sphereD, sin(time)*.05-.55));
		d = min(d, boxD);
    }


    res.x = d;
    return res;

   return res;
}

vec3 gyr_norm(vec3 p) {
	// specific to the gyroid_sdf function
	return normalize(vec3(
		cos(p.x)*cos(p.y) - sin(p.x)*sin(p.z),
		cos(p.y)*cos(p.z) - sin(p.x)*sin(p.y),
		cos(p.x)*cos(p.z) - sin(p.y)*sin(p.z)
	));
}


vec3 getNormal(vec3 p) {
    // return gyr_norm(p);
	float eps = 0.001;
	vec2 e = vec2(1.0, -1.0) * 0.5773 * eps;

	return normalize(vec3(
		scene(p + e.xyy).x - scene(p + e.yyy).x,
		scene(p + e.yxy).x - scene(p + e.yyy).x,
		scene(p + e.yyx).x - scene(p + e.yyy).x
	));
}

// IQ soft shadow function
// https://iquilezles.org/articles/rmshadows/
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ) {
	float res = 1.0;
	float t = mint;
	for (int i = 0; i < 256 && t < maxt; i++){
		float h = scene(ro + rd*t).x;
		if (h<0.001)
			return 0.0;
		res = min(res, k*h/t);
		t += h;
	}
	return res;
}

// Cosine color palette function from Inigo Quilez
vec3 getColor(float amount, vec3 pal) {
  vec3 color = 0.3 + 0.5 * cos(6.2831 * (pal + amount * vec3(1.4, 1.0, 1.0)));
//   color = vec3(color.y*color.x);
  return color * amount;
}

float computeLineLightAnalytic(vec3 p, vec3 n,
                              vec3 A, vec3 B,
                              float intensity) {
    vec3  AB    = B - A;
    float t     = clamp(dot(p - A, AB)/dot(AB, AB), 0.0, 1.0);
    vec3  closest = A + AB * t;
    vec3  L     = normalize(closest - p);
    float diff  = max(dot(n, L), 0.0);
    float dist  = length(closest - p);
    float att   = 1.0 / (1.0 + dist*dist);
    return diff * att * intensity;
}

const int NUM_POINT_LIGHTS = 2;
vec3 pointLightPos[NUM_POINT_LIGHTS] = vec3[](
	vec3(sin(lTime*.78), sin(lTime*.54), cos(lTime*.94)) * pathSize,
	vec3(cos(lTime*.77), sin(lTime*.93), cos(lTime*.83)) * pathSize
);

vec3 computeLighting(vec3 p, vec3 n, vec2 sret) {
	vec3 outCol = vec3(0.0);

    // 1) Half-Lambert directional + ambient
    const vec3 sunDir   = normalize(vec3(0.8, 0.6, -0.5));
    float sunInt        = .5;
    float ambient       = .8;
    float lambert       = max(dot(n, sunDir), 0.0);
    lambert             = lambert * 0.5 + 0.5;
    float lighting      = ambient + sunInt * lambert;

	outCol += getColor(lighting*.35, vec3(0.0, 0.1, 0.2));


    // outCol -= softshadow(p, sunDir, 0.1, 8.0, 64.0); // Soft shadows

    // 2) multiple point-lights via small LUT
	vec3 palettes[NUM_POINT_LIGHTS] = vec3[](
		vec3(0.1, 0.0, 0.2),
		vec3(0.1, 0.0, 0.1)
    );
    // float pointLightInt[NUM_POINT_LIGHTS] = float[](2.0, 1.5, 1.0, 1.5, 1.4);
    for (int i = 0; i < NUM_POINT_LIGHTS; ++i) {
        vec3 lp   = pointLightPos[i];
        vec3 L    = normalize(lp - p);
        float diff = max(dot(n, L), 0.0);
        float dist = length(lp - p)*.01; // bigger multi = smaller light
        float att  = 1.0 / (4.0 + dist*dist);
		float lighting = 1. * diff * att;

		// outCol += getColor(lighting, palettes[i])+vec3(sret.x*.2);
		outCol += getColor(lighting, vec3(0.1, 0.2, 0.02))+vec3(sret.x*.2);
    }



    return outCol;
}

float calcAO(vec3 p, vec3 n) {
    // simple hemisphere AO
    float ao = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 * float(i + 1);
        float d = scene(p + n * h).x;
        ao += (h - d) * sca;
        sca *= 0.5;
    }
    return clamp(1.0 - ao, 0.0, 1.0);
}

const int   MAX_VOL_STEPS = 32;
const float SIGMA_S       = 8.0;    // scattering coefficient
const float SIGMA_T       = 0.08;    // extinction coefficient
const float G_PHASE       = 0.24;   // Henyey–Greenstein anisotropy
const vec3  LIGHT_DIR     = normalize(vec3(0.5, 0.3, -0.9));
const vec3  LIGHT_COL     = vec3(1.0, 0.9, 0.7);
const float FOG_FALLOFF = 4.0;

// Henyey–Greenstein phase function
float phaseHG(float cosTheta) {
    float g = G_PHASE;
    float denom = pow(1.0 + g*g - 2.0*g*cosTheta, 1.5);
    return (1.0 - g*g) / (4.0 * PI * denom);
}

vec4 integrateVolumetric(vec3 ro, vec3 rd, float tMax) {
    float dt    = tMax / float(MAX_VOL_STEPS);
    float tCurr = 0.0;
    vec3  trans = vec3(1.0);
    vec3  col   = vec3(0.0);
    for (int i = 0; i < MAX_VOL_STEPS; ++i) {
        vec3 pos    = ro + rd * (tCurr + 0.5 * dt);
        float density = 1.0;                       // uniform fog
        float phase   = phaseHG(dot(rd, LIGHT_DIR));
        vec3  insc    = LIGHT_COL * SIGMA_S * phase;
        col   += trans * insc * density * dt;
        trans *= exp(-SIGMA_T * density * dt);
        tCurr += dt;
    }
    return vec4(col, trans.x);
}

const float BAND_SPEED = 0.1;            // how fast it runs down
const float BAND_WIDTH = 0.05;            // half‐width of the band
const vec3  BAND_COLOR = vec3(1.0,0.6,0.3);

vec4 raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        vec3 p = ro + rd * t;
        float d = scene(p).x;
        if (d < minDist) {
            float tHit    = t;
            vec4 vol      = integrateVolumetric(ro, rd, tHit);
            vec3 n        = getNormal(p);
            vec3 base     = computeLighting(p, n, scene(p).yz);
            float rim     = pow(1.0 - dot(n, -rd), 2.0) * 0.5;
            vec3 glow     = vec3(1.0,0.6,0.2) * rim;
			float ao      = calcAO(p, n);
            vec3 surfCol  = base + glow * ao;
            // blend surface with fog
            // — pulse‐band along the tunnel —
            float pos   = fract(tHit * BAND_SPEED - time*0.05);
            float dBand = abs(pos - 0.5);
            float band  = smoothstep(BAND_WIDTH, 0.0, dBand);
            surfCol     += BAND_COLOR * band;

            return vec4(surfCol * vol.w + vol.xyz*.25, 1.);
        }
        if (t > maxDist) break;
        t += d;
    }
    // miss: full fog to horizon
    vec4 vol = integrateVolumetric(ro, rd, maxDist);
    return vec4(vol.xyz, 1.0);
}

void main() {
    // screen uv
    vec2 uv = (gl_FragCoord.xy - 0.5*uResolution.xy) / uResolution.y;


	vec3 ro = vec3(0.0, 0.0, -3.);
    vec3 rd       = normalize(vec3(uv, 0.8));


	rd = rotate_z_point(rd, time*.1);

    fragColor     = raymarch(ro, rd);
}