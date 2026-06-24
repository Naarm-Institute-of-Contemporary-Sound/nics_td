/*
 * ball cube things for Auricular repousse
 * by @auricular
 * 20/06/2025 :)
 */

// UNIFORMS
uniform float time;
uniform float low;
uniform float iLow;
uniform float rms;
uniform float rmsAc;
out vec4 fragColor;


// CONSTANTS
#define PI 3.14159265359
#define TAU 6.28318530718

float timeVar =  low * 0.033  + time * 0.04 + rmsAc * 0.01;
float timeVar2 = low * 0.045 + time * 0.05 + rmsAc * 0.015;
vec2 uResolution = uTDOutputInfo.res.zw;


float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float scene(vec3 p) {
    float d = 1e10;
    vec3 bp = p;
    bp.z -= 2.0;

    float c02 = cos(timeVar * 0.33);
    float c04 = cos(timeVar * 0.66);
    float blend = sin(time * 0.15 + 0.3) * 0.4 + 0.5;

    float depth = 1.;//iLow*1.2 + 1.2;

    for (int i = 0; i < 16; i++) {
        float fi = float(i);
        float si = sin(timeVar + fi * 0.3);
        float co = cos(timeVar2 - fi * 2.5) * 0.5 + cos(0.3 + timeVar2 - fi * 1.3) * 0.5;
        float z = cos(fi)*depth * sin(fi * 2.)*depth;
        vec3 off = vec3(si * c04 * 0.9 + c02 * 0.6, co * 0.88, z * 0.8);
        vec3 pp = bp - off;

        float s = sphereSDF(pp, 0.3);
        float b = sdBox(pp, vec3(0.3));
        float blendSDF = mix(s, b, blend); // faster than two smooth unions
        d = opSmoothUnion(d, blendSDF, .5-(clamp(rms, 0.0, 1.0)*0.2));
    }

    return d;
}


vec3 getNormal(vec3 p) {
    float eps = 0.005;
    vec2 h = vec2(1.0, -1.0) * 0.5773 * eps;

    return normalize(vec3(
        scene(p + h.xyy) - scene(p + h.yyy),
        scene(p + h.yxy) - scene(p + h.yyy),
        scene(p + h.yyx) - scene(p + h.yyy)
    ));
}


vec3 getColor(float a) {
    return (0.3 + 0.5 * cos(TAU * (vec3(0.0, 0.1, 0.2) + a * vec3(.7, .8, 1.)))) * a;
}

float softshadow(vec3 ro, vec3 rd) {
    float res = 1.0, t = 0.1;
    for (int i = 0; i < 32; i++) {
        float h = scene(ro + rd * t);
        if (h < 0.001) return 0.0;
        res = min(res, 32.0 * h / t);
        t += h;
        if (t > 5.0) break;
    }
    return res;
}

vec4 raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 128; i++) {
        vec3 p = ro + rd * t;
        float d = scene(p);
        if (d < 0.001) {
            vec3 n = getNormal(p);
            vec3 lightDir = normalize(vec3(cos(timeVar * 0.09), sin(timeVar * 0.03) * 1.3, -1.3-1.*2.));
            // vec3 light2Dir = normalize(vec3(cos(timeVar * 0.1 + .3), sin(timeVar * 0.05 + .2) * 2.0, -1.0));
            float diff = max(dot(n, lightDir), 0.0);
            // float diff2 = max(dot(n, light2Dir), 0.0);
            float shadow = softshadow(p, lightDir);
            // float shadow2 = softshadow(p, light2Dir);
            float lighting = diff * shadow ;
            vec3 color = getColor(lighting - 0.05);
            return vec4 (color, 1.0);
        }
        if (t > 64.0) break; // early bailout
        t += d;
    }
    return vec4(0.0); // background
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * uResolution .xy) / uResolution.y;
    vec3 ro = vec3(0.0, 0.0, -2.);
    vec3 rd = normalize(vec3(uv, 1.-(0.)));
    fragColor = raymarch(ro, rd);

    fragColor = tanh(fragColor * 1.6);
}
