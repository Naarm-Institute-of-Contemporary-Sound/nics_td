//#define sabs(p) sqrt(p*p+1e-2)
//#define smin(a,b) (a+b-sabs(a-b))*.5
//#define smax(a,b) (a+b+sabs(a-b))*.5

#define MAX_MARCHING_STEPS 100

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define TAU atan(1.)*8.

/*
 *
 * Main Phong Code
 *
 */

vec2 sceneSDF(vec3 samplePoint);



float cube(vec3 p,vec3 s)
{
	vec3 q = abs(p);
	vec3 m = max(s-q,0.);
	return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}


/*
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p)
{
	return normalize(vec3(
		sceneSDF(vec3(p.x + EPSILON, p.y, p.z)).x - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)).x,
		sceneSDF(vec3(p.x, p.y + EPSILON, p.z)).x - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)).x,
		sceneSDF(vec3(p.x, p.y, p.z + EPSILON)).x - sceneSDF(vec3(p.x, p.y, p.z - EPSILON)).x
	));
}

mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll)
{
	vec3 rr = vec3(sin(roll), cos(roll), 0.0);
	vec3 ww = normalize(target - origin);
	vec3 uu = normalize(cross(ww, rr));
	vec3 vv = normalize(cross(uu, ww));

	return mat3(uu, vv, ww);
}


vec2 shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end)
{
	float depth = start;
	vec2 ret;

	for (int i = 0; i < MAX_MARCHING_STEPS; i++)
	{
		ret = vec2(0.0, float(i));
		vec2 tmp = sceneSDF(eye + depth * marchingDirection);
		float dist = tmp.x;
		//ret.y = tmp.y;
		ret.y = i;

		if (dist < EPSILON)
		{
			ret.x = depth;
			return ret;
		}

		depth += dist;

		if (depth >= end)
		{
			ret.x = end;
			return ret;
		}
	}
	ret.x = end;
	ret.y = end;
	return ret;
}

float AmbientOcclusion(vec3 point, vec3 normal, float stepDistance)
{
	float occlusion =1.;
	for (float samples = 2.0; samples > 0.0; samples--)
		occlusion -= (samples * stepDistance - (sceneSDF(point + normal * samples * stepDistance).x)) / pow(4.0, samples); // Set higher power for increased falloff
	return occlusion;
}



vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 n, vec3 eye,
						  vec3 lightPos, vec3 lightIntensity)
{
	vec3 N = n;
	vec3 L = normalize(lightPos - p);
	vec3 V = normalize(eye - p);
	vec3 R = normalize(reflect(-L, N));

	float dotLN = dot(L, N);
	float dotRV = dot(R, V);

	// Light not visible from this point on the surface
	if (dotLN < 0.0)
		return vec3(0.0, 0.0, 0.0);

	vec3 col;


	// Light reflection in opposite direction as viewer, apply only diffuse
	// component
	if (dotRV < 0.0)
		col = lightIntensity * (k_d * dotLN);
	else
		col = lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));

	return col;
}


vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_d_2, vec3 k_s, float alpha,
					   vec3 p, vec3 n, vec3 eye, vec3 intensity, float ambIntens,
					   vec3 l1pos, vec3 l2pos)
{
	vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0)*ambIntens;
	vec3 color = ambientLight * k_a;

	vec3 light1Pos = l1pos;

	vec3 light1Intensity = intensity;

	color += phongContribForLight(k_d, k_s, alpha, p, n, eye,
					light1Pos,
					light1Intensity);

	vec3 light2Pos = l2pos;
	vec3 light2Intensity = intensity;

	color += phongContribForLight(k_d_2, k_s, alpha, p, n, eye,
					light2Pos,
					light2Intensity);
	return color;
}

vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha,
					   vec3 p, vec3 n, vec3 eye, vec3 intensity, float ambIntens,
					   vec3 l1pos)
{
	vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0)*ambIntens;
	vec3 color = ambientLight * k_a;

	vec3 light1Pos = l1pos;

	vec3 light1Intensity = intensity;

	color += phongContribForLight(k_d, k_s, alpha, p, n, eye,
					light1Pos,
					light1Intensity);
	return color;
}

/*
 * Misc helpers
 */
vec3 rotate_y_x_point(vec3 pt, float x, float y) // TODO: Optimize
{
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

vec3 rotate_y_point(vec3 pt, float y) // TODO: Optimize
{
	mat4 Ry = mat4(
	vec4(cos(y), 0, sin(y), 0),
	vec4(0, 1, 0, 0),
	vec4(-sin(y), 0, cos(y), 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Ry);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}

vec3 rotate_x_point(vec3 pt, float x) // TODO: Optimize
{
	mat4 Rx = mat4(
	vec4(1, 0, 0, 0),
	vec4(0, cos(x), -sin(x), 0),
	vec4(0, sin(x), cos(x), 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Rx);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}


vec3 rotate_z_point(vec3 pt, float z) // TODO: Optimize
{
	mat4 Rz = mat4(
	vec4(cos(z), -sin(z), 0, 0),
	vec4(sin(z), cos(z), 0, 0),
	vec4(0, 0, 1, 0),
	vec4(0, 0, 0, 1));

	mat4 inv = inverse(Rz);
	vec3 new_pt = (vec4(pt, 1) * inv).xyz;
	return new_pt;
}


vec3 rayDirection(float fov, vec2 size, vec2 fragCoord, vec3 rot)
{
	vec2 xy = fragCoord - size / 2.0; // Normalize coordinates
	float z = size.y / tan(radians(fov) / 2.0);
	return rotate_y_x_point(normalize(vec3(xy, -z)), rot.x, rot.y); // TODO: Have it not be shit
}

float rand(vec2 co)
{
	return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float rand(float a, float b)
{
	return rand(vec2(a, b));
}


vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float sdf_sphere(vec3 rayPoint, vec3 center, float radius)
{
	return distance(rayPoint, center) - radius;
}

float sdf_plane(vec3 p, vec4 pos) // Ground plane
{
	return dot(p, pos.xyz) + pos.w; // xyz for angle, w for distance from origin
}

float vmax(vec3 v)
{
	return max(max(v.x, v.y), v.z);
}

float sdf_box(vec3 p, vec3 c, vec3 s)
{
	return vmax(abs(p-c) - s);
}

float opRep(vec3 p, vec3 c)
{
	vec3 q = mod(p+0.5*c,c)-0.5*c;
	return sdf_box(q, vec3(0.0, 0.0, 0.0), vec3(0.02));
}

float repeat(float d, float domain)
{
	return mod(d, domain)-domain/2.0;
}

float opSmoothUnion(float d1, float d2, float k)
{
	float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
	return mix(d2, d1, h) - k*h*(1.0-h);
}

float sdSphere( vec3 p, float s )
{
	return length(p)-s;
}

float sdf_torus(vec3 pos, vec3 xyz, vec2 t)
{
	vec2 q = vec2(length(xyz.xy - pos.xy) - t.x, xyz.z - pos.z);
	return length(q) - t.y;
}


/*
 * Playing with translations - Testing code
 */
vec3 translatePoint(vec3 pt, float time)
{

	vec3 scale = vec3(1.0); // MUST BE >= 1
	mat4 S = mat4(
	vec4(scale.x, 0, 0, 0),
	vec4(0, scale.y, 0, 0),
	vec4(0, 0, scale.z, 0),
	vec4(0, 0, 0, 1));

	float t = time*0.1;
	mat4 Rz = mat4(
	vec4(cos(t), sin(t), 0, 0),
	vec4(-sin(t), cos(t), 0, 0),
	vec4(0, 0, 1, 0),
	vec4(0, 0, 0, 1));
	mat4 Rx = mat4(
	vec4(1, 0, 0, 0),
	vec4(0, cos(t), -sin(t), 0),
	vec4(0, sin(t), cos(t), 0),
	vec4(0, 0, 0, 1));
	vec3 coords = vec3(-0.3, -0.1, 0.0);
	mat4 T = mat4(
	vec4(1, 0, 0, coords.x),
	vec4(0, 1, 0, coords.y),
	vec4(0, 0, 1, coords.z),
	vec4(0, 0, 0, 1));

	mat4 prod = S * Rx * T;
	prod = S * T * Rx * Rz;
	//prod = T;
	mat4 inv = inverse(prod);

	vec3 new_pt = (vec4(pt, 1) * inv).xyz;

	return new_pt;
}



/*
 * Post Processing Code
 */
vec3 encodeSRGB(vec3 linearRGB)
{
	vec3 a = 12.92 * linearRGB;
	vec3 b = 1.055 * pow(linearRGB, vec3(1.0 / 2.4)) - 0.055;
	vec3 c = step(vec3(0.0031308), linearRGB);
	return mix(a, b, c);
}

float getVideoPixLuma(sampler2D video, vec2 pos)
{
	pos = mod(pos, 1.);

	pos -= 0.1;
	pos *= 0.9;
	pos += 0.19;

	float x = pos.x;
	//float y = pos.y * 0.992 - 0.992;
	float y = pos.y;

	float luma = texture(video, vec2(-x, -y)).r;
	luma = 1.1643 * (luma - 0.0625) + 0.2;

	return luma;
}

vec3 getVideoPixel(sampler2D video, vec2 pos)
{
	pos = mod(pos, 1.);
	float k1 = 1.0;
	float k2 = 0.34;
	float k3 = 0.789;
	float k4 = 0.5;

	pos -= 0.1;
	pos *= 0.9;
	pos += 0.19;

	float x = pos.x;
	//float y = pos.y * 0.992 - 0.992;
	float y = pos.y;
	//x *= 0.7;
	//y *= 0.7;

	float xCutThresh = 0.0005;
	float yCutThresh = 0.001;
	if (x < xCutThresh || x > 1.0-xCutThresh || y < yCutThresh || y > 1.0-yCutThresh)
		return vec3(0.0, 0.0, 0.0);

	// YUV -> RGB
	float luma = texture(video, vec2(-x, -y)).r;
	float h = 0.50;
	float d = 2.0;
	float u = texture(video, vec2(-x/d-h, -y/d-h)).g;
	float v = texture(video, vec2(-x/d-h, -y/d-h)).b;
	y = 1.1643 * (y - 0.0625);
	u = u - 0.25;
	v = v - 0.25;
	y = luma;
	float r = y + 1.5958 * v;
	float g = y - 0.39173 * u - 0.81290 * v;
	float b = y + 2.017 * u;

	if(r > 1.0)
		r = 1.0;
	if(b > 1.0)
		b = 1.0;
	if(g > 1.0)
		g = 1.0;

	if(r < 0.0)
		r = 0.0;
	if(g < 0.0)
		g = 0.0;
	if(b < 0.0)
		b = 0.0;

	//float sContrastValue = 1.0;
	//float sBrightnessValue = 0.0;
	float sContrastValue = k1;
	float sBrightnessValue = k2;
	r = r * sContrastValue + sBrightnessValue;
	g = g * sContrastValue + sBrightnessValue;
	b = b * sContrastValue + sBrightnessValue;

	vec3 outie = vec3(r, g, b);

	float gamma = k3;
	outie = pow(outie, vec3(1.0 / gamma)); // Gamma Correction on Video

	outie = smoothstep(0.0, 1.0, outie);

	return outie;
	//return vec3(luma);
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = sceneSDF(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

vec3 pixelSort(sampler2D tex, vec2 pos, vec2 res)
{
	vec3 outCol;

	const int maxSliceSize = 128;
	int softMax = int(maxSliceSize * 1.);
	int softMin = 16;
	float roundSize = 0.005;
	float texCoordRound = pos.x - mod(pos.x, roundSize);
	int sliceSize = int(mod(rand(vec2(texCoordRound, 0.5)), 1.0) * (softMax - softMin)) + softMin;
	float texCoord = pos.y * res.y;
	int slicePos = int(mod(texCoord, sliceSize));
	int starty = int(texCoord) - slicePos;
	float pix[maxSliceSize + 2];
	int pixi[maxSliceSize + 2];
	int smallestI = sliceSize;
	for (int i = 0; i < sliceSize; i++)
	{
		float y = getVideoPixLuma(tex, vec2(pos.x, float(starty + i) / res.y)).r;
		pix[i] = y;
		pixi[i] = i;
	}

	float max = 1.0 - 0.8;
	float min = 1.0 - 0.4;
	float ycutoff = mod(rand(vec2(texCoordRound, 0.5 + 1.)), 1.0) * (max - min) + min;

	if (pos.y > ycutoff)
	{
		int min_index = 0;
		float temp = 0;
		int tempi = 0;
		int n = sliceSize;
		for (int i = 0; i < n; i++)
		{
			min_index = i;
			for (int j = i; j < n; j++)
			{
				//compare min index's element with new j's element
				//if you want descending sort you can change the binary
				//operator > to < .
				if (pix[min_index] > pix[j]) min_index = j;
			}
			//change min index's element and i. element
			temp = pix[min_index];
			tempi = pixi[min_index];
			pix[min_index] = pix[i];
			pixi[min_index] = pixi[i];
			pix[i] = temp;
			pixi[i] = tempi;
		}

		float texY = float(starty + pixi[slicePos]) / res.y;
		float maxY = 0.009;
		if (texY < maxY)
			texY = maxY;
		outCol = getVideoPixel(tex, vec2(pos.x, texY));
	}
	else
		outCol = getVideoPixel(tex, vec2(pos.xy));

	return outCol;
}





vec4 gaussianBlur(sampler2D text, vec2 pos, vec2 res, float size)
{
	// GAUSSIAN BLUR SETTINGS {{{
	float Pi = 6.28318530718; // Pi*2
	float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
	float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
	float Size = 128.0*size; // BLUR SIZE (Radius)
	// GAUSSIAN BLUR SETTINGS }}}

	vec2 Radius = Size/res;

	// Normalized pixel coordinates (from 0 to 1)
	// Pixel colour
	vec4 Color = texture(text, pos.xy);

	// Blur calculations
	for( float d=0.0; d<Pi; d+=Pi/Directions)
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
			Color += texture(text, pos.xy+vec2(cos(d),sin(d))*Radius*i);

	// Output to screen
	Color /= Quality * Directions - 15.0;

	return Color;
}

vec3 gaussianVideoBlur(sampler2D video, vec2 pos, vec2 res, float size)
{
	// GAUSSIAN BLUR SETTINGS {{{
	float Pi = 6.28318530718; // Pi*2
	float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
	float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
	float Size = 128.0*size; // BLUR SIZE (Radius)
	// GAUSSIAN BLUR SETTINGS }}}

	vec2 Radius = Size/res;

	// Normalized pixel coordinates (from 0 to 1)
	// Pixel colour
	vec3 Color = getVideoPixel(video, pos.xy);

	// Blur calculations
	for( float d=0.0; d<Pi; d+=Pi/Directions)
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
			Color += getVideoPixel(video, pos.xy+vec2(cos(d),sin(d))*Radius*i);

	// Output to screen
	Color /= Quality * Directions - 15.0;

	return Color.xyz;
}



vec4 getThreshPixel(sampler2D pic, vec2 pos, float thresh)
{
	vec4 pix = texture(pic, pos);

	float total = pix.r+pix.g+pix.b;
	total /= 3;

	if (total < thresh)
		pix = vec4(vec3(0.0), 1.0);

	return pix;
}

vec4 bloom(sampler2D image, vec2 uv, vec2 res, float size, float thresh)
{

	/*float direction = 6.0;
	vec2 resolution = iResolution.xy;
	vec4 Color = vec4(0.0);
	vec2 off1 = vec2(1.411764705882353) * direction;
	vec2 off2 = vec2(3.2941176470588234) * direction;
	vec2 off3 = vec2(5.176470588235294) * direction;
	Color += getThreshPixel(image, uv, thresh) * 0.1964825501511404;
	Color += getThreshPixel(image, uv + (off1 / resolution), thresh) * 0.2969069646728344;
	Color += getThreshPixel(image, uv - (off1 / resolution), thresh) * 0.2969069646728344;
	Color += getThreshPixel(image, uv + (off2 / resolution), thresh) * 0.09447039785044732;
	Color += getThreshPixel(image, uv - (off2 / resolution), thresh) * 0.09447039785044732;
	Color += getThreshPixel(image, uv + (off3 / resolution), thresh) * 0.010381362401148057;
	Color += getThreshPixel(image, uv - (off3 / resolution), thresh) * 0.010381362401148057;*/


	// GAUSSIAN BLUR SETTINGS {{{
	float Pi = 6.28318530718; // Pi*2
	float Directions = 40.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
	float Quality = 4.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
	float Size = 128.0*size; // BLUR SIZE (Radius)
	// GAUSSIAN BLUR SETTINGS }}}

	vec2 Radius = Size/res;

	// Normalized pixel coordinates (from 0 to 1)
	// Pixel colour
	vec4 Color = getThreshPixel(image, uv.xy, thresh);

	// Blur calculations
	for( float d=0.0; d<Pi; d+=Pi/Directions)
		for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
			Color += getThreshPixel(image, uv.xy+vec2(cos(d),sin(d))*Radius*i, thresh);

	// Output to screen
	Color /= Quality * Directions - 15.0;

	return Color;
}


float calculateShadow(vec3 p, vec3 lpos)
{
	float shadowStrength = 0.0;
	vec3 N = estimateNormal(p);

	vec3 lightVec = normalize(lpos - p); // Vector to light // L

	vec2 shadowHit = shortestDistanceToSurface(p, lightVec, 0.001, 128.);
	float dist = shadowHit.x;
	float closestDist = shadowHit.y;

	float fullDist = distance(p, lpos);
	float diff = dist - fullDist;
	if (diff <= 0.0) // If we're in the shadow
		shadowStrength += 0.5*abs(diff/dist);


	return shadowStrength;
}

float rand(float n)
{
	return fract(sin(n) * 43758.5453123);
}

float gyroid(vec3 p, float scale, float bias, float thickness)
{
	p *= scale;
	float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
	return d/scale;
}


// DOF function borrowed from XT95
const float GA = 2.399;
#define DOF_SAMPLES 40
mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
vec3 dof(sampler2D tex,vec2 uv,float rad, vec2 iResolution)
{
	vec3 acc=vec3(0);
	vec2 pixel=vec2(.003*iResolution.y/iResolution.x,.003),angle=vec2(0,rad);;
	rad=1.;
	for (int j=0; j < DOF_SAMPLES; j++)
	{
		rad += 1./rad;
		angle*=rot;
		vec4 col=texture(tex,uv+pixel*(rad-1.)*angle);
		acc+=col.xyz;
	}
	return acc/float(DOF_SAMPLES);
}

mat2 Rot(float a)
{
	float s = sin(a), c = cos(a);
	return mat2(c, -s, s, c);
}


float sdf_capsule(vec3 p, float h, float r)
{
	p.y -= clamp(p.y, 0.0, h);
	return length(p) - r;
}

float sdf_box_frame(vec3 p, vec3 b, float e)
{
	p = abs(p) - b;
	vec3 q = abs(p + e) - e;
	return min(min(
		length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
		length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
		length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}


float swrand(vec3 n)
{
	return fract(sin(dot(n, vec3(12.9898, 4.1414, 7.81293))) * 43758.5453);
}

float noise(vec3 p)
{
	vec3 ip = floor(p);
	vec3 u = fract(p);
	u = u*u*(3.0-2.0*u);

	float res = mix(
		mix(swrand(ip),swrand( ip + vec3(1.0,0.0,1.0)), u.x),
		mix(swrand(ip+vec3(0.0,1.0,0.0)),swrand(ip+vec3(1.0,1.0,1.0)),u.x),u.y);
	return res*res;
}

const mat3 m3 = mat3(0.8, -0.6, 0.6, 0.8, 0.3,-0.3, 0.7, -0.2, -0.4);

float fbm(in vec3 p)
{
	float f = 0.0;
	f += 0.5000*noise(p); p = m3*p*2.02;
	f += 0.2500*noise(p); p = m3*p*2.03;
	f += 0.1250*noise(p); p = m3*p*2.01;
	f += 0.0625*noise(p);

	return f/0.769;
}

float pattern(in vec3 p)
{
	vec3 q = vec3(fbm(p + vec3(0.0,0.0,0.0)));
	vec3 r = vec3(fbm(p + 4.0*q + vec3(1.7,9.2,1.8)));
	return fbm(p + 0.00001*r);
}

vec3 wavePattern(vec3 p)
{
	float displacement = pattern(p);
	vec3 wave = vec3(displacement * 1.2, 0.3, displacement * 5);

	return wave;
}


mat3 lookAt(vec3 origin, vec3 target, float roll)
{
	vec3 rr = vec3(sin(roll), cos(roll), 0.0);
	vec3 ww = normalize(target - origin);
	vec3 uu = normalize(cross(ww, rr));
	vec3 vv = normalize(cross(uu, ww));

	return mat3(uu, vv, ww);
}


#define SC (250.0)

float random(vec2 p)
{
	return fract(p.x*p.y*fract(p.x*0.1183099));
}

float noise(in vec2 uv)
{
	return sin(uv.x)+cos(uv.y);
}

#define OCTAVES 8
float fbm(in vec2 uv)
{
	float value = 0.;
	float amplitude = 1.;
	float freq = 0.8;

	for (int i = 0; i < OCTAVES; i++)
	{
		// value += noise(uv * freq) * amplitude;

		// From Dave_Hoskins https://www.shadertoy.com/user/Dave_Hoskins
		value += (.25-abs(noise(uv * freq)-.3) * amplitude);

		amplitude *= (.47+value)/2.0;

		freq *= 2.;

		uv += uv.yx/16.0;
		uv = uv.yx;
	}
	return value;
}

float f(in vec3 p)
{
	float h = fbm(p.xz);
	return h;
}

vec2 pmod(vec2 p, float n)
{
  float a=mod(atan(p.y, p.x),TAU/n)-.5 *TAU/n;
  return length(p)*vec2(sin(a),cos(a));
}


float sabs(float x)
{
	return sqrt(x*x+1e-4);
}

vec2 sfold(vec2 p)
{
  vec2 v=normalize(vec2(1,-1));
  float g=dot(p,v);
  return p-(g-sabs(g))*v;
}


void signedSFold(inout vec2 p, vec2 v)
{
	float g=dot(p,v);
	p=(p-(g-sabs(g))*v)*vec2(sign(g),1);
}

void sFold90(inout vec2 p)
{
	vec2 v=normalize(vec2(1,-1)); ;
	float g=dot(p,v);
	p-=(g-sabs(g))*v;
}

float box(vec3 p, vec3 s)
{
	p=abs(p)-s;
	sFold90(p.xz);
	sFold90(p.yz);
	sFold90(p.xy);
	return p.x;
}

float expStep( float x, float k, float n ){
	return exp( -k*pow(x,n) );
}


// Finna OC
vec3 modClamp(vec3 x, float ma, float mi)
{
	vec3 outp = x;

	outp = mod(x, mi)+mi;

	return outp;
}

void mengerFold(inout vec4 z)
{
	float a = min(z.x - z.y, 0.0);
	z.x -= a;
	z.y += a;
	a = min(z.x - z.z, 0.0);
	z.x -= a;
	z.z += a;
	a = min(z.y - z.z, 0.0);
	z.y -= a;
	z.z += a;
}
void sierpinskiFold(inout vec4 z)
{
	z.xy -= min(z.x + z.y, 0.0);
	z.xz -= min(z.x + z.z, 0.0);
	z.yz -= min(z.y + z.z, 0.0);
}
void rotX(inout vec4 z, float s, float c)
{
	z.yz = vec2(c*z.y + s*z.z, c*z.z - s*z.y);
}
void rotY(inout vec4 z, float s, float c)
{
	z.xz = vec2(c*z.x - s*z.z, c*z.z + s*z.x);
}
void rotZ(inout vec4 z, float s, float c)
{
	z.xy = vec2(c*z.x + s*z.y, c*z.y - s*z.x);
}
void rotX(inout vec4 z, float a)
{
	rotX(z, sin(a), cos(a));
}
void rotY(inout vec4 z, float a)
{
	rotY(z, sin(a), cos(a));
}
void rotZ(inout vec4 z, float a)
{
	rotZ(z, sin(a), cos(a));
}


float de_tetrahedron(vec4 p, float r)
{
	float md = max(max(-p.x - p.y - p.z, p.x + p.y - p.z),
	max(-p.x + p.y + p.z, p.x - p.y + p.z));
	return (md - r) / (p.w * sqrt(3.0));
}

//TODO: COMBINE FUNCS
float mandelBulb(in vec4 pos, out vec3 col)
{

	float fracAng1 = 0.002*32.2;//+(ubo.time*0.0009);
	float fracAng2 = 1*16.0+(0.9);

	const int FRACTAL_ITER = 64;


	vec4 newP = pos;
	for (int i = 0; i < FRACTAL_ITER; i++)
	{
		newP.xyz = abs(newP.xyz);
		sierpinskiFold(newP);
		mengerFold(newP);
		rotZ(newP, fracAng1);
		rotX(newP, fracAng2);
		col = max(col, newP.xyz * vec3(0.03));
	}
	return de_tetrahedron(newP, 4.0);
}


// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
	float h = max(k-abs(a-b),0.0);
	return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
	float h = max(k-abs(a-b),0.0);
	return max(a, b) + h*h*0.25/k;
}

float scene(vec3 v);

float intersection(in vec3 ro, in vec3 rd)
{
	const float maxd = 15.0;
	const float precis = 0.001;
	float h = precis*2.0;
	float t = 0.0;
	float res = -1.0;

	for (int i = 0; i < 90; i++)
	{
		if (h < precis || t > maxd)  break;

		h = scene( ro+rd*t );
		t += h;
	}

	if (t < maxd) res = t;
	return res;
}

vec3 calcNormal( in vec3 pos )
{
	const float eps = 0.002;

	const vec3 v1 = vec3( 1.0,-1.0,-1.0);
	const vec3 v2 = vec3(-1.0,-1.0, 1.0);
	const vec3 v3 = vec3(-1.0, 1.0,-1.0);
	const vec3 v4 = vec3( 1.0, 1.0, 1.0);

	return normalize( v1*scene( pos + v1*eps ) +
					  v2*scene( pos + v2*eps ) +
					  v3*scene( pos + v3*eps ) +
					  v4*scene( pos + v4*eps ) );
}


// vec3 background(vec3 rd)
// {
// 	return getVideoPixel(texSampler, rd.xy).rgb;
// }

vec3 calcLight( in vec3 pos , in vec3 camdir, in vec3 lightp, in vec3 lightc, in vec3 normal , in vec3 texture)
{
	vec3 lightdir = normalize(pos - lightp);
	float cosa = pow(0.6+0.5*dot(normal, -lightdir),2.5);
	float cosr = max(dot(-camdir, reflect(lightdir, normal)),0.0);

	vec3 diffuse = 1.0 * cosa * texture;
	vec3 phong = vec3(1.0 * pow(cosr, 67.0));

	return lightc * (diffuse + phong);
}

// vec3 illuminate(in vec3 pos, in vec3 camdir)
// {
// 	vec3 normal = calcNormal(pos);


// 	const float ETA = 0.9;
// 	vec3 refrd = -refract(camdir,normal,ETA);
// 	vec3 refro = pos + 10.0 * refrd;
// 	float refdist = intersection(refro, refrd);
// 	vec3 refpos = refro + refdist * refrd;
// 	vec3 refnormal = calcNormal(refpos);

// 	float pixelScale = 1.0;
// 	float clampTop = 0.8;
// 	float clampBot = 0.2;
// 	float brightness = 1.;
// 	float blur = 0.1;


// 	vec3 tex0 = gaussianVideoBlur(texSampler, refract(-refrd,-refnormal,1.0/ETA).xy*pixelScale, ubo.resolution.xy, blur).rgb*brightness;
// 	vec3 tex1 = gaussianVideoBlur(texSampler, refract(-refrd,-refnormal,1.0/ETA).xy*pixelScale, ubo.resolution.xy, blur).rgb*brightness;
// 	if (refdist < -0.5)
// 	{
// 		tex0 = background(modClamp(-refrd, clampTop, clampBot))*brightness;
// 		tex1 = tex0;
// 	}
// 	vec3 tex2 = gaussianVideoBlur(texSampler, reflect(camdir,normal).xy*pixelScale, ubo.resolution.xy, blur).rgb*brightness;
// 	vec3 tex3 = gaussianVideoBlur(texSampler, reflect(camdir,normal).xy*pixelScale, ubo.resolution.xy, blur).rgb*brightness;
// 	vec3 texture = vec3(1.0,0.9,0.9)* (0.4 * tex0 + 0.4 * tex1 + 0.03 * tex2 + 0.1 * tex3);

// 	vec3 l1 = calcLight(pos, camdir, vec3(0.0,10.0,-20.0), vec3(1.0,1.0,1.0), normal, texture);
// 	vec3 l2 = calcLight(pos, camdir, vec3(-20,10.0,0.0), vec3(1.0,1.0,1.0), normal, texture);
// 	vec3 l3 = calcLight(pos, camdir, vec3(20.0,10.0,0.0), vec3(1.0,1.0,1.0), normal, texture);
// 	vec3 l4 = calcLight(pos, camdir, vec3(0.0,-10.0,20.0), vec3(0.6,0.6,0.6), normal, texture);
// 	return l1+l2+l3+l4;
// }

// --------------------------------------------------------
// Spectrum colour palette
// IQ https://www.shadertoy.com/view/ll2GD3
// --------------------------------------------------------

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
	return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
	return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}


vec3 mod289(vec3 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x)
{
  return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec3 fade(vec3 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
float cnoise(vec3 P)
{
	vec3 Pi0 = floor(P); // Integer part for indexing
	vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
	Pi0 = mod289(Pi0);
	Pi1 = mod289(Pi1);
	vec3 Pf0 = fract(P); // Fractional part for interpolation
	vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
	vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
	vec4 iy = vec4(Pi0.yy, Pi1.yy);
	vec4 iz0 = Pi0.zzzz;
	vec4 iz1 = Pi1.zzzz;

	vec4 ixy = permute(permute(ix) + iy);
	vec4 ixy0 = permute(ixy + iz0);
	vec4 ixy1 = permute(ixy + iz1);

	vec4 gx0 = ixy0 * (1.0 / 7.0);
	vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
	gx0 = fract(gx0);
	vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
	vec4 sz0 = step(gz0, vec4(0.0));
	gx0 -= sz0 * (step(0.0, gx0) - 0.5);
	gy0 -= sz0 * (step(0.0, gy0) - 0.5);

	vec4 gx1 = ixy1 * (1.0 / 7.0);
	vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
	gx1 = fract(gx1);
	vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
	vec4 sz1 = step(gz1, vec4(0.0));
	gx1 -= sz1 * (step(0.0, gx1) - 0.5);
	gy1 -= sz1 * (step(0.0, gy1) - 0.5);

	vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
	vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
	vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
	vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
	vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
	vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
	vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
	vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

	vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
	g000 *= norm0.x;
	g010 *= norm0.y;
	g100 *= norm0.z;
	g110 *= norm0.w;
	vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
	g001 *= norm1.x;
	g011 *= norm1.y;
	g101 *= norm1.z;
	g111 *= norm1.w;

	float n000 = dot(g000, Pf0);
	float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
	float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
	float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
	float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
	float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
	float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
	float n111 = dot(g111, Pf1);

	vec3 fade_xyz = fade(Pf0);
	vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
	vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
	float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
	return 2.2 * n_xyz;
}

float surface3( vec3 coord ) {
	float frequency = 4.0;
	float n = 0.0;

	n += 1.0    * abs( cnoise( coord * frequency ) );
	n += 0.5    * abs( cnoise( coord * frequency * 2.0 ) );
	n += 0.25   * abs( cnoise( coord * frequency * 4.0 ) );

	return n;
}


// Classic Perlin noise, periodic variant
float pnoise(vec3 P, vec3 rep)
{
  vec3 Pi0 = mod(floor(P), rep); // Integer part, modulo period
  vec3 Pi1 = mod(Pi0 + vec3(1.0), rep); // Integer part + 1, mod period
  Pi0 = mod289(Pi0);
  Pi1 = mod289(Pi1);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 * (1.0 / 7.0);
  vec4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 * (1.0 / 7.0);
  vec4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}




float snoise(vec3 v)
{
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i);
  vec4 p = permute( permute( permute(
			 i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
		   + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
		   + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
								dot(p2,x2), dot(p3,x3) ) );
}



// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


 //Complex Math:
vec2 complexExp(in vec2 z){
	return vec2(exp(z.x)*cos(z.y),exp(z.x)*sin(z.y));
}
vec2 complexLog(in vec2 z){
	return vec2(log(length(z)), atan(z.y, z.x));
}
vec2 complexMult(in vec2 a,in vec2 b){
	return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}
float complexMag(in vec2 z){
	return float(pow(length(z), 2.0));
}
vec2 complexReciprocal(in vec2 z){
	return vec2(z.x / complexMag(z), -z.y / complexMag(z));
}
vec2 complexDiv(in vec2 a,in vec2 b){
	return complexMult(a, complexReciprocal(b));
}
vec2 complexPower(in vec2 a, in vec2 b){
	return complexExp( complexMult(b,complexLog(a))  );
}
//Misc Functions:
float nearestPower(in float a, in float base){
	return pow(base,ceil(log(abs(a))/log(base))-1.0 );
}
float drostmap(float value, float istart, float istop, float ostart, float ostop) {
	   return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}


// vec3 zoomCamEye()
// {
// 	vec3 cameraAt = vec3(0.0);

// 	float angleX = 0.0;
// 	float angleY = 0.0;
// 	vec3 cameraPos	= (vec3(sin(angleX)*cos(angleY), sin(angleY), cos(angleX)*cos(angleY))) * 8.0*(1.0-s1)+1.0;


// 	return cameraPos;
// }

// vec3 zoomCamDir(vec3 eye)
// {
// 	vec3 cameraAt = vec3(0.0);

// 	float angleX = 0.0;
// 	float angleY = 0.0;

// 	vec3 cameraPos	= eye;

// 	vec3 cameraFwd = normalize(cameraAt - cameraPos);
// 	vec3 cameraLeft = normalize(cross(normalize(cameraAt - cameraPos), vec3(0.0,sign(cos(angleY)),0.0)));
// 	vec3 cameraUp = normalize(cross(cameraLeft, cameraFwd));

// 	float cameraViewWidth	= 32.0*(s2);
// 	float cameraViewHeight	= cameraViewWidth * iResolution.y / iResolution.x;
// 	float cameraDistance	= 2.0;  // intuitively backwards!

// 	//----- Ray Setup
// 	vec2 rawPercent = (fragCoord.xy / iResolution.xy);
// 	vec2 percent = rawPercent - vec2(0.5,0.5);

// 	vec3 rayTarget = (cameraFwd * vec3(cameraDistance,cameraDistance,cameraDistance))
// 		- (cameraLeft * percent.x * cameraViewWidth)
// 		+ (cameraUp * percent.y * cameraViewHeight);
// 	vec3 rayDir = normalize(rayTarget);


// 	return rayDir;
// }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }