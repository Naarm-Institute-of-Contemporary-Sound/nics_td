/*
 * DAY 17 - rotatey frac
 * by @auricular
 * 20/05/2025 :)
 */

// uniform float exampleUniform;

// Add a global uniform variable
float blendFactor = 1.0;
uniform float time;
uniform float low;
uniform float lowAc;
uniform float rms;
uniform float rmsAc;


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

float lTime = 3.0;
float pathSize = 2.; // Varying path size for randomness

mat3 SetRot( const in vec4 q )
{
	vec4 qSq = q * q;
	float xy2 = q.x * q.y * 2.0;
	float xz2 = q.x * q.z * 2.0;
	float yz2 = q.y * q.z * 2.0;
	float wx2 = q.w * q.x * 2.0;
	float wy2 = q.w * q.y * 2.0;
	float wz2 = q.w * q.z * 2.0;

	return mat3 (
     qSq.w + qSq.x - qSq.y - qSq.z, xy2 - wz2, xz2 + wy2,
     xy2 + wz2, qSq.w - qSq.x + qSq.y - qSq.z, yz2 - wx2,
     xz2 - wy2, yz2 + wx2, qSq.w - qSq.x - qSq.y + qSq.z );
}
mat3 SetRot( vec3 vAxis, float fAngle )
{
	return SetRot( vec4(normalize(vAxis) * sin(fAngle), cos(fAngle)) );
}
mat3 SetRotWarped(vec3 vAxis, float fAngle)
{
    const float window   = 0.9;
    const float speedUp  = 3.0;


    float k     = round(fAngle / PI);
    float base  = k * PI;


    float delta = fAngle - base;


    float warpedAngle;
    if (abs(delta) < window) {

        float n = abs(delta) / window;


        float warpedDelta = sign(delta) * m * window;
        warpedAngle = base + warpedDelta;
    }
    else {
        // outside the zone, no warp
        warpedAngle = fAngle;
    }


    vec4 q = vec4(normalize(vAxis) * sin(warpedAngle),
                  cos(warpedAngle));
    return SetRot(q);
}


const int maxSteps = 256;
const float maxDist = 512.0;
const float minDist = 0.001;


float scene(vec3 p) {
    const float SCALE  = 1.5;
    const vec3  OFFSET = vec3(-1.81);//vec3(-2.2+.9*sin(lowAc*.001), -.6+.3*cos(rmsAc*.02), -.5+.2*sin(lowAc*.03));
    mat3 rot = SetRotWarped(vec3(0.2+123.*sin(lowAc*.0004),2.+128.*sin(rmsAc*.0009),0.3), sin(time*.01)*.7+1.4);

    float totalScale = 1.0;
    // Fold/scale/offset/rotate loop
    for(int i = 0; i < 15; i++) {
        p = abs(p);
        p = p * SCALE + OFFSET;
        p = rot * p + OFFSET;
        totalScale *= SCALE;
    }

    // Distance to fractal boundary at radius 0.1
    return length(p) / totalScale - 0.02;
}


vec3 getNormal(vec3 p) {
	float eps = 0.001;
	vec2 e = vec2(1.0, -1.0) * 0.5773 * eps;

	return normalize(vec3(
		scene(p + e.xyy) - scene(p + e.yyy),
		scene(p + e.yxy) - scene(p + e.yyy),
		scene(p + e.yyx) - scene(p + e.yyy)
	));
}

// IQ soft shadow function
// https://iquilezles.org/articles/rmshadows/
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ) {
	float res = 1.0;
	float t = mint;
	for (int i = 0; i < 256 && t < maxt; i++){
		float h = scene(ro + rd*t);
		if (h<0.001)
			return 0.0;
		res = min(res, k*h/t);
		t += h;
	}
	return res;
}

// Cosine color palette function from Inigo Quilez
vec3 getColor(float amount, vec3 pal) {
  vec3 color = .2 + .3 * cos(6.2831 * (pal + amount * vec3(.25, .25, .25)));
//   color = vec3(color.y*color.x);
  return color;
}

const int NUM_POINT_LIGHTS = 2;
// vec3 pointLightPos[NUM_POINT_LIGHTS] = vec3[](
// 	vec3(sin(lTime*.78), sin(lTime*.54), cos(lTime*.94)) * pathSize,
// 	vec3(cos(lTime*.77), sin(lTime*.93), cos(lTime*.83)) * pathSize
// );

vec3 pointLightPos[NUM_POINT_LIGHTS] = vec3[](
    vec3(.0, 1., 0.),
    vec3(.0, -1., 0.)
);

vec3 computeLighting(vec3 p, vec3 n) {
	vec3 outCol = vec3(0.0);


    const vec3 sunDir   = normalize(vec3(0.8, 0.6, -0.5));
    float sunInt        = .5;
    float ambient       = .8;
    float lambert       = max(dot(n, sunDir), 0.0);
    lambert             = lambert * 0.5 + 0.5;
    float lighting      = ambient + sunInt * lambert;

	outCol += getColor(lighting*.35, vec3(.1, cos(time*0.13)*.3+.5, sin(time*0.1)*.3+.5))*.3;
    // outCol -= softshadow(p, sunDir, 0.1, 8.0, 64.0); // Soft shadows


	// vec3 palettes[NUM_POINT_LIGHTS] = vec3[](
	// 	vec3(0.1, 0.0, 0.2),
	// 	vec3(0.1, 0.0, 0.1)
    // );
    // // float pointLightInt[NUM_POINT_LIGHTS] = float[](2.0, 1.5, 1.0, 1.5, 1.4);
    // for (int i = 0; i < NUM_POINT_LIGHTS; ++i) {
    //     vec3 lp   = pointLightPos[i];
    //     vec3 L    = normalize(lp - p);
    //     float diff = max(dot(n, L), 0.0);
    //     float dist = length(lp - p)*.00001; // bigger multi = smaller light
    //     float att  = 1.0 / (1.0 + dist*dist);
	// 	float lighting = 1. * diff * att;

	// 	// outCol += getColor(lighting, palettes[i])+vec3(sret.x*.2);
	// 	outCol += getColor(lighting*4.,  vec3(.1, 1.5, 0.3))*lighting;
    // }



    return outCol;
}


float calcAO(vec3 p, vec3 n) {
    // simple hemisphere AO
    float ao = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.3 * float(i + 1);
        float d = scene(p + n * h).x;
        ao += (h - d) * sca;
        sca *= 0.5;
    }
    return clamp(1.0 - ao, 0.0, 1.0);
}

const float BAND_SPEED = 0.1;            // how fast it runs down
const float BAND_WIDTH = 0.05;
vec3  BAND_COLOR = getColor(0.5, vec3(0.7, 0.7, 0.6));

vec4 raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        vec3 p = ro + rd * t;
        float d = scene(p);
        if (d < minDist) {
            float tHit    = t;
            // vec4 vol      = integrateVolumetric(ro, rd, tHit);
            vec3 n        = getNormal(p);
            vec3 base     = computeLighting(p, n);
            float rim     = pow(1.0 - dot(n, -rd), 2.0) * 0.5;
            vec3 glow     = vec3(1.0,0.6,0.2) * rim;
			float ao      = calcAO(p, n);
            vec3 surfCol  = base + glow * ao*4.;
            // blend surface with fog
            // — pulse‐band along the tunnel —
            float pos   = fract(tHit * BAND_SPEED - time*0.03);
            float dBand = abs(pos - 0.5);
            float band  = smoothstep(BAND_WIDTH, 0.0, dBand);
            surfCol     += BAND_COLOR * band;

            // surfCol = vec3(ao*.6);

            // return vec4(surfCol * vol.w + vol.xyz*.25, 1.);
            return vec4(surfCol, 1.0);
        }
        if (t > maxDist) break;
        t += d;
    }

    return vec4(0.0);
}

void main() {
    // screen uv
    vec2 uv = (gl_FragCoord.xy - 0.5*uResolution.xy) / uResolution.y;


	vec3 ro = vec3(0.0, 0.0, -9.);
    vec3 rd = normalize(vec3(uv, 1.));


    float t = mod(time*3., 50.0);

    // vec2 pxy = gl_FragCoord.xy;
    // vec2 uv  = (pxy - 0.5 * uResolution.xy) / uResolution.y;
    float radius      = 10.5;
    float targetHeight= 0.0;
    float orbitSpeed  = 0.01;

    float camX        = radius * cos(time * orbitSpeed) + sin(time * 0.2) * 0.5;
    float camZ        = radius * sin(time * orbitSpeed) + cos(time * 0.3) * 0.5;
    float camY        = targetHeight + sin(time * 0.4) * 0.5;
    camY = 0.0;
    ro           = vec3(camX, camY, camZ);
    vec3 target       = vec3(0.0, targetHeight, 0.0);
    vec3 up           = vec3(0.0, 1.0, 0.0);
    mat3 viewMatrix   = lookAt(ro, target, up);
    rd           = normalize(viewMatrix * vec3(uv, .8));

	// rd = rotate_z_point(rd, time*.1);

    fragColor     = raymarch(ro, rd);

    // gamma correct
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));
}