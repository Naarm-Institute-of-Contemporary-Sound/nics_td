// this copy from the email is all fucked up
// missing brackets etc.


layout(location = 0) out vec4 fragColor;

uniform float time;

uniform float lightx;
uniform float lighty;


const int MAX_STEPS = 128;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;
const float PI = 3.14159265359;

// ratio of phase velocity of light in vacuum /
// phase velocity of light in material between materials
const float IOR = 1.5;
const float F0 = pow((1.0 - IOR) / (1.0 + IOR), 2.0);


// length = √(x² + y² + z²) - radius
float sdf_sphere(vec3 pos) {
    return length(pos)-1.0;
}


float sdf_scene(vec3 pos) {
    float movScale = .4;
    pos.x -= sin(time*.005)*movScale;
    pos.y -= cos(time*.005)*movScale;
    return sdf_sphere(pos);
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


vec3 estimateNormal(vec3 pos) {
    vec2 e = vec2(EPSILON, 0.0);

    return normalize(vec3(
        sdf_scene(pos+e.xyy)-sdf_scene(pos-e.xyy),
        sdf_scene(pos+e.yxy)-sdf_scene(pos-e.yxy),
        sdf_scene(pos+e.yyx)-sdf_scene(pos-e.yyx)
    ));
}

vec2 directionToSphereUV(vec3 dir) {
    dir = normalize(dir); // Make the direction a unit vector; we only care about its direction.

    float u = atan(dir.z, dir.x)/(2.0*PI)+0.5; // Calculate horizontal angle and map it from -PI..PI to 0..1.
    float v = asin(clamp(dir.y, -1.0, 1.0))/PI+0.5; // Calculate vertical angle and map it from -PI/2..PI/2 to 0..1.

    return vec2(u, v); // Return the spherical direction as a 2D texture coordinate.
}


vec3 sampleEnvironment(vec3 dir) {
    return texture(
        sTD2DInputs[0],
        directionToSphereUV(dir)
    ).rgb;
}


vec3 phong(vec3 hitPos, vec3 eye, vec3 lightPos) {
vec3 normal = estimateNormal(hitPos);

vec3 lightDir = normalize(lightPos-hitPos);

vec3 viewDir = normalize(eye-hitPos);

vec3 reflectDir = reflect(-lightDir, normal);


// background light bouncing off stuff around it etc.
float ambient = 0.1;


// overall direct light
float diffuse = max(dot(normal, lightDir), 0.0);


// geordie
float specular = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);


vec3 objectColor = vec3(0.0, 1.0, 0.0);

vec3 lightColor = vec3(1.0);


return objectColor*(ambient+diffuse)*lightColor+specular*lightColor;
}


float fresnelSchlick(float cosTheta, float f0) {
return f0+(1.0-f0)*pow(1.0-cosTheta, 5.0);
}


// :^)
void main() {
vec2 res = uTDOutputInfo.res.zw;

float fov = 60.0;

vec3 eye = vec3(0.0, 0.0, 5.0);

vec3 rayDir = rayDirection(fov, res);


float depth = march(eye, rayDir);


vec3 color = depth < MAX_DIST ? vec3(1.0) : vec3(0.0);


if (depth < MAX_DIST) {
vec3 hitPos = eye+depth*rayDir;

vec3 normal = estimateNormal(hitPos);
color = normal*0.5+0.5;

vec3 lightPos = vec3(lightx*5., 5., lighty*5.);
vec3 lightDir = normalize(lightPos-hitPos);
vec3 phongColor = phong(hitPos, eye, lightPos);
color = phongColor;


vec3 reflectionDir = reflect(rayDir, normal);
vec3 reflectionColor = sampleEnvironment(reflectionDir);
color = reflectionColor;


float eta = 1.0/IOR;
vec3 transmissionDir = refract(rayDir, normal, eta);
vec3 transmissionColor = sampleEnvironment(-transmissionDir);
color = transmissionColor;


vec3 viewDir = normalize(eye-hitPos);
float cosTheta = max(dot(normal, viewDir), 0.0);
float fresnel = fresnelSchlick(cosTheta, F0);
// color = vec3(fresnel);

vec3 glassColor = mix(
transmissionColor,
reflectionColor,
fresnel
);
// color = glassColor;
}

else {
color = sampleEnvironment(rayDir);
}


fragColor = TDOutputSwizzle(vec4(color, 1.0));
}

