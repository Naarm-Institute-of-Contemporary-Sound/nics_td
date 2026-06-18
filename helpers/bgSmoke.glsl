// movie aroundy bg tool

uniform float time;
uniform float trailB;
uniform float low;
uniform TDTexInfo uTDOutputInfo;

#define PI  3.1415926535897932384626433832795
#define TAU 6.2831853071795864769252867665590

vec2 uResolution = uTDOutputInfo.res.zw;

out vec4 fragColor;


const float MAX_TRAIL_B = 0.995;


//------------------------------------------------------------------------------
// Convert RGB to HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0,  2.0/3.0, -1.0);
    vec4 p = mix(
        vec4(c.bg, K.wz),
        vec4(c.gb, K.xy),
        step(c.b, c.g)
    );
    vec4 q = mix(
        vec4(p.xyw, c.r),
        vec4(c.r, p.yzx),
        step(p.x, c.r)
    );
    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return vec3(
        abs(q.z + (q.w - q.y) / (6.0 * d + e)),
        d / (q.x + e),
        q.x
    );
}

//------------------------------------------------------------------------------
// Convert HSV back to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//------------------------------------------------------------------------------
// Simple pseudo-random hash
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

//------------------------------------------------------------------------------
// 2D value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f*f*(3.0 - 2.0*f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

//------------------------------------------------------------------------------
// Curl (vector field) displacement
vec2 curl(vec2 uv) {
    float e = 0.01;
    float dx = noise(uv + vec2(e, 0.0)) - noise(uv - vec2(e, 0.0));
    float dy = noise(uv + vec2(0.0, e)) - noise(uv - vec2(0.0, e));
    return vec2(dy, -dx); // rotate 90°
}
vec3 palette(float t) {
    float hueShift = .1 * 0.0005;
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.33, 0.67) + vec3(hueShift, hueShift * 0.5, -hueShift * 0.25);
    return a + b * cos(6.28318 * (c * t + d));
}

//------------------------------------------------------------------------------
// Main fragment shader
void main() {
    vec2 uv = vUV.st;
    vec3 res = vec3(uResolution.xy, 64.);

    vec2 cUV = uv - 0.5;         // centre-relative
    float r2 = dot(cUV, cUV);    // squared radius, cheap & monotonic
    r2 = smoothstep(0.0, 0.8, r2); // smooth radial falloff



    float zoomStrength = .0;//.1+low*.1;    // strength of radial zoom effect

    // --- radial zoom warp ---------------------------------------
    // factor <1 → pull sample inward → appears to enlarge when drawn
    float zoom = 1.0 / (1.0 + zoomStrength * r2);
    vec2 warpUV = cUV * zoom + 0.5 + vec2(sin(time * 0.001 + uv.y * 10.0) * 0.01, cos(time * 0.001 + uv.x * 10.0) * 0.01)*.12;

    // warpUV = vec2(
    //     cUV.x * (1.0 / (1.0 + zoomStrength * r2)),
    //     cUV.y * (1.0 / (1.0 + zoomStrength * abs(cUV.y)))
    //     ) + 0.5;



    // Base color (with a tiny chromatic offset)
    float offScale = 0.00;
    float r = texture(sTD2DInputs[0], warpUV + vec2(0.0, 0.1) * offScale).r;
    float g = texture(sTD2DInputs[0], warpUV + vec2(0.1, 0.0) * offScale).g;
    float b = texture(sTD2DInputs[0], warpUV + vec2(0.1, 0.1) * offScale).b;
    vec4 color = vec4(r, g, b, texture(sTD2DInputs[0], warpUV).a);

    // Displace by curl field
    vec2 disp = curl(warpUV * (sin(low) * 10.0 + 90.0) + time * 0.01) * 0.05;

    // Sample previous frame
    vec4 prev = texture(sTD2DInputs[1], warpUV + disp);

    // Advect along hue-based direction
    vec3 prevHSV = rgb2hsv(prev.rgb);
    float angle = prevHSV.x * TAU + warpUV.x * TAU - warpUV.y * TAU;
    vec2 dir = vec2(cos(angle), sin(angle));
    vec4 adv = texture(
        sTD2DInputs[1],
        uv + dir * 0.02 * (low + 0.05)
    );

    // Blend trail
    float blendAmt = smoothstep(0.15, 0.0, color.a);
    if (blendAmt > 0.0) {
        vec3 blendRGB = mix(prev.rgb, adv.rgb, 0.5);
        color += vec4(blendRGB, 1.0) * MAX_TRAIL_B * trailB * blendAmt;
    }

    vec2 dir2   = cUV * 0.02;
    vec4 tap0  = texture(sTD2DInputs[1], warpUV);
    vec4 tap1  = texture(sTD2DInputs[1], warpUV + dir2);

    vec3 streak = mix(tap0.rgb, tap1.rgb, 0.5);

    // extra CA on the streaked sample
    vec2 ca = 0.0015 * cUV;
    streak.r = texture(sTD2DInputs[1], warpUV + ca).r;
    streak.b = texture(sTD2DInputs[1], warpUV - ca).b;

    color.rgb = mix(color.rgb, streak, 0.35);


    // Vignette
    float d = distance(uv, vec2(0.5));
    float vig = smoothstep(0.8, 0.5, d);
    color.rgb *= vig;

    // Output
    fragColor = TDOutputSwizzle(color);

    // fragColor.rgb = tanh(fragColor.rgb * 1.1)*.9;
}




    // const int iterations = 100;
    // const float stepSize = 1.0 / float(iterations);
    // const float zRepeats = 1.5;

    // float upScale = 0.0;
    // // vec2 uv = gl_FragCoord.xy / res.xy;

    // // Center UV, maintain aspect
    // vec2 centered = (uv * res.xy / res.y) - vec2(0.5 * res.x / res.y, 0.5);

    // // === Dynamic cam controls from audio + time
    // float slider = .5;
    // float fov      = mix(.2, .9, slider);               // Zoom level based on low freq
    // float zStart   = mix(.3, .9, slider);   // Depth start, animated
    // float zDir     = mix(.4, .9, slider);            // Forward motion
    // float fisheye  = mix(-3., .0, slider);          // Slight curvature
    // float zSpacing = mix(.2, 1., slider);  // <-- increase this for more perceived depth
    // // float curl = sin(time * 0.2 + uv.y * 10.0) * 0.02;

    // // Apply fisheye warp
    // vec2 warped = centered * (1.0 + dot(centered, centered) * fisheye);
    // // warped.x += curl;

    // vec3 rayOrigin = vec3(uv, zStart);
    // vec3 rayDir = normalize(vec3(warped * fov, zDir));

    // // vec4 color = vec4(0.0);

    // for (int i = 0; i < iterations; ++i) {
    //     float t = float(i) * stepSize;
    //     vec3 samplePos = rayOrigin + t * rayDir;

    //     // Wrap Z more
    //     // Amplify Z travel to exaggerate depth separation
    //     samplePos = rayOrigin + t * vec3(rayDir.xy, rayDir.z * zSpacing);
    //     samplePos.z = fract(samplePos.z * zRepeats);


    //     if (any(lessThan(samplePos, vec3(0.0))) || any(greaterThan(samplePos, vec3(1.0))))
    //         continue;

    //     float val = texture(sTD3DInputs[0], samplePos).r;
    //     if (val > 0.05) {
    //         float att = 1.0 - smoothstep(-2.0, 2.0, t);
    //         // color.rgb += palette(val * 8.0 + att) * att * val * mix(.09, .14, slider);
    //         color.rgb += palette(float(i+0.0)/iterations) * att * val * mix(.09, .14, slider) * 0.005;
    //     }
    // }



    // fragColor = TDOutputSwizzle(color);