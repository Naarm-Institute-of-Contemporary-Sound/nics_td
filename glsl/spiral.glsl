/*
 * DAY ?? - SPIRAL
 * by @auricular
 * 20/05/2025 :)
 */

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


vec3 cosinePalette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TAU * (c * t + d));
}


vec3 getPaletteColor(float t, float paletteBlend) {
    // -- define each palette at parameter t --
    vec3 p0 = cosinePalette(t,
        vec3(0.4),           // a0
        vec3(0.4),           // b0
        vec3(1.0,0.1,0.35),   // c0
        vec3(0.3,0.2,0.4));   // d0

    vec3 p1 = cosinePalette(t,
        vec3(0.3),           // a1
        vec3(0.5),           // b1
        vec3(0.9,0.3,0.2),   // c1
        vec3(0.0,0.1,0.2));   // d1

    vec3 p2 = cosinePalette(t,
        vec3(0.3,0.4,0.3),   // a2
        vec3(0.4,0.3,0.0),   // b2
        vec3(1.0,0.5,0.0),   // c2
        vec3(0.25));         // d2

    // wrap paletteBlend into [0,3) so we cycle
    float u = mod(paletteBlend * 3.0, 3.0);
    float f = fract(u);

    // pick which two palettes to mix
    vec3 a = (u < 1.0) ? p0
           : (u < 2.0) ? p1
           :             p2;
    vec3 b = (u < 1.0) ? p1
           : (u < 2.0) ? p2
           :             p0;

    return mix(a, b, f);
}


void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * uResolution.xy) / uResolution.y;

    vec3 ro = vec3(.0, .0, rmsAc*.001+time*.1); // camera origin
    vec3 rd = normalize(vec3(uv, sin(time*.03))); // ray direction

    float maxDist = 2.0;
    float twistSpeed   = 1.5;
    float twistPhase   = 0.5;
    float glowStrength = 0.5;

    float twistTime = rmsAc*0.05;
    float warpTime = lowAc*0.05+rmsAc*.04;

    vec3 color = vec3(0.0);
    float t     = 0.0;

    for (int i = 0; i < 128; i++) {
        if (t > maxDist) break;

        // 1) world point + warp
        vec3 p    = ro + rd * t;
        vec3 warp = vec3(
            p.x * 12.2 + sin(p.z * 0.4 + warpTime * 0.3) * 1.0,
            p.y * 12.0 + cos(p.z * 0.3 + warpTime * 0.2) * 1.0,
            p.z * 3.5 + warpTime * 1.5
        );

        // 2) twist in XY
        mat2 twist = mat2(
            cos(warp.z*twistSpeed + twistTime*twistPhase), -sin(warp.z*twistSpeed + twistTime*twistPhase),
            sin(warp.z*twistSpeed + twistTime*twistPhase),  cos(warp.z*twistSpeed + twistTime*twistPhase)
        );
        warp.xy *= twist;

        // 3) inline “fbm‑ish” noise → density d
        float s    = sin(warp.x + warp.y);
        float nAcc = 1.0;
        for (int j = 0; j < 4; j++) {
            s    -= abs(dot(cos(rmsAc*0.3 + warp * nAcc), vec3(0.3))) / nAcc;
            nAcc *= 2.0;
        }
        float d = clamp(s, 0.0, 1.0);

        // 4) base palette color
        float paletteBlend = mod(time * 0.05, 1.0);
        vec3 baseCol = getPaletteColor(d, paletteBlend) * d;

        // 8) accumulate with depth fade
        float fade = exp(-0.1 * t);
        color += baseCol * fade * 0.3;

        t += 0.01;
    }

    // final glow + gamma
    color = tanh(color * glowStrength);
    // color = pow(color, vec3(.8));

    fragColor = vec4(color, 1.0);
}
