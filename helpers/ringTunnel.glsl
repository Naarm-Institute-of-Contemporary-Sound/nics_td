/*
 * DAY ?? - TUNNEL Rings
 * by @auricular
 * 20/05/2025 :)
 */

uniform float time,meta,lowAc,rms,rmsAc,songDir,low;
vec2 uResolution=uTDOutputInfo.res.zw;
out vec4 fragColor;

const float TAU=6.28318530718;
const float INV_TAU=1./TAU;
const float SECTION=1.02498944652;
const float INV_SECTION=1./SECTION;
const float RING_COUNT=1226.;
const float INV_RING_COUNT=1./RING_COUNT;
const vec3 LDIR=vec3(.412948321,.688247202,-.596480908);
const vec3 COLOR_PALETTE=vec3(0.8, 0.3, 0.1);

vec3 spec(float p){
    return .5+.5*cos(TAU*(p+vec3(0,.33,.67)));
}

// Cosine color palette function from Inigo Quilez
vec3 getColor(float amount, vec3 pal) {
  vec3 color = .2 + .3 * cos(6.2831 * (pal + amount * vec3(.15, .25, .25)));
//   color = vec3(color.y*color.x);
  return color;
}

vec3 getBackgroundPalette(float amount){
	return spec(amount);
	// return vec3(.0);
	return getColor(amount, COLOR_PALETTE);
}

vec3 getRingPalette(float amount){
	return spec(amount);
	return getColor(amount, COLOR_PALETTE);
}

float pulse(float i){
	float p=fract(i/7.-rmsAc*.01);
	p=max(1.-abs(p-.5)*2.,0.);
	float p2=p*p;
	return p2*p2*p2;
}

vec3 cen(float z){
	return vec3(-6.*sin(z*.11)+1.3*cos(z*.14),
				-4.7*cos(z*.14)-3.5*sin(z*.11),z);
}

float spin(float i){
	float p=i*TAU*INV_RING_COUNT,t=time*.35;
	return t*.1+p*8.+13.5*sin(p*3.+t*.043)+.55*sin(p*11.-t*.071);
}

float ring(vec3 p,float i){
	float z=i*SECTION;
	vec3 a=normalize(vec3(-.66*cos(z*.11)-.182*sin(z*.14),
						   .658*sin(z*.14)-.385*cos(z*.11),1));
	vec3 q=p-cen(z),rgt=normalize(cross(vec3(0,1,0),a));
	float y=dot(q,a),v=clamp(rms,0.,1.),r=.58+v*.25;
	q-=a*y;

	vec2 x=vec2(dot(q,rgt),dot(q,cross(a,rgt)));
	float t=spin(i),c=cos(t),s=sin(t);
	x=mat2(c,-s,s,c)*x;

	float rails=length(vec2(abs(abs(x.x)-r),max(abs(x.y)-r,0.)));
	vec2 b=abs(x)-vec2(r*.82);
	float box=abs(length(max(b,0.))+min(max(b.x,b.y),0.));
	return length(vec2(mix(rails,box,.852212482048),y))-.055*(1.+v*.16);
}

vec2 map(vec3 p){
	float i=floor(p.z*INV_SECTION),a=ring(p,i),b=ring(p,i+1.);
	return a<b?vec2(a,i):vec2(b,i+1.);
}

float noise(vec3 p){
	vec3 i=floor(p),f=fract(p),u=f*f*f*(f*(f*6.-15.)+10.);
	float n=0.;
	for(int k=0;k<8;k++){
		vec3 o=vec3(float(k&1),float((k>>1)&1),float((k>>2)&1));
		vec3 w=mix(1.-u,u,o);
		vec3 g=fract((i+o)*vec3(.1031,.1030,.0973));
		g+=dot(g,g.yxz+33.33);
		g=fract((g.xxy+g.yxx)*g.zyx)*2.-1.;
		n+=dot(g,f-o)*w.x*w.y*w.z;
	}
	return clamp(.5+.65*n,0.,1.);
}

void main(){
	vec2 uv=(gl_FragCoord.xy-.5*uResolution)/uResolution.y;

	float speed=1.+clamp(songDir,0.,100.)*.00001;
	float travel=time*.25+lowAc*.2*speed;
	float z=mod(travel,1256.63706144);
	vec3 ro=cen(z);

	vec3 fwd=normalize(cen(z+1.5)-ro);
	vec3 r=normalize(cross(vec3(0,1,0),fwd)),u=cross(fwd,r);
	float roll=spin(z*INV_SECTION)+1.57079632679,cr=cos(roll),sr=sin(roll);
	float zoom=mix(.25,1.5,clamp(meta,0.,1.));
	vec3 rd=normalize(mat3(r*cr+u*sr,u*cr-r*sr,fwd)*vec3(uv,.6*zoom));

	float bp=atan(rd.y,rd.x)*INV_TAU+rd.z*.18-time*.025;
	float by=1.-abs(rd.y),by2=by*by;
	// vec3 bkg=vec3(.003,.005,.012)+spec(bp)*(.025+.075*by2*by);
	vec3 bkg=vec3(.003,.005,.012)+getBackgroundPalette(bp)*(.025+.075*by2*by);

	float id=0.,t=0.,hitD=1e9;
	vec3 glow=vec3(0);
	bool hit=false;

	// Inlined march(): primary SDF raymarch plus active-pulse glow.
	for(int i=0;i<96;i++){
		vec2 h=map(ro+rd*t);
		id=h.y;
		hitD=h.x;

		if(h.x<.25){
			float mp=pulse(id);
			// if(mp>.001)glow+=spec(fract(id*INV_RING_COUNT)*4.-time*.16)*mp*8.
			if(mp>.001)glow+=getRingPalette(fract(id*INV_RING_COUNT)*4.-time*.16)*mp*8.
						 *exp(-16.*abs(h.x))*.22;
		}

		if(h.x<.001){
			hit=true;
			break;
		}
		t+=max(h.x*.75,.003);
		if(t>48.)break;
	}
	glow=min(glow,vec3(8));

	float p=0.,far=40.;
	vec3 surf=vec3(0);

	if(hit){
		float pp=pulse(id);
		p=smoothstep(.03,.4,pp);
		far=mix(30.,t,p);

		// finite-difference normal at the SDF hit.
		vec3 hp=ro+rd*t;
		vec2 ne=vec2(.001,0);
		vec3 n=normalize(vec3(map(hp+ne.xyy).x-hitD,
							  map(hp+ne.yxy).x-hitD,
							  map(hp+ne.yyx).x-hitD));

		// vec3 v=-rd,b=spec(fract(id*INV_RING_COUNT)*4.-time*.16)*pp*8.;
		vec3 v=-rd,b=getRingPalette(fract(id*INV_RING_COUNT)*4.-time*.16)*pp*8.;
		float d=.25+.75*max(dot(n,LDIR),0.);
		float s=pow(max(dot(n,normalize(LDIR+v)),0.),80.);
		float e=1.-max(dot(n,v),0.),e2=e*e;
		e=e2*e2*e;

		vec3 lit=b*(.5+d*.8+e*.5)+mix(vec3(1),b,.45)*s*pp;
		// vec3 rgb=spec(fract(id*INV_RING_COUNT)*6.-time*.16);
		vec3 rgb=getRingPalette(fract(id*INV_RING_COUNT)*6.-time*.16);
		vec3 idle=bkg*.68+rgb*(.075+.16*e)+vec3(.3,.36,.46)*s*.9;
		surf=mix(mix(idle,lit,smoothstep(.02,.35,pp)),bkg,1.-exp(-t*.026));
	}

	// the fog is coming the fog is coming volume march for gaussian smoke field
	float tr=1.;
	vec3 f=vec3(0);
	float end=min(far,40.),step=end/18.;
	float j=fract(sin(dot(vec3(gl_FragCoord.xy,0),vec3(127.1,311.7,74.7)))*43758.5453);
	for(int i=0;i<18;i++){
		vec3 fp=ro+rd*((float(i)+.35+.55*j)*step);

		// curved-tunnel keepout, smoke veins, energy and hue.
		float fz=fp.z;
		vec3 fa=normalize(vec3(-.66*cos(fz*.11)-.182*sin(fz*.14),
								.658*sin(fz*.14)-.385*cos(fz*.11),1));
		vec3 fq=fp-cen(fz);
		float keep=smoothstep(2.28,3.2,length(fq-fa*dot(fq,fa)));
		if(keep<.001)continue;

		vec3 rr=normalize(cross(vec3(0,1,0),fa));
		float ang=atan(dot(fq,cross(fa,rr)),dot(fq,rr));
		vec3 sp=fp*.14+vec3(time*.025,0,-time*.00875);
		vec3 np=sp*.72;
		float body=.65*noise(np)+.35*noise(np.yzx*1.93+vec3(1.7,-2.4,.9));
		float ridge=1.-abs(noise(sp*2.6+4.7)*2.-1.);
		float ridge2=ridge*ridge;
		ridge=ridge2*ridge2*ridge;

		float spiral=.5+.5*sin(ang*3.+fz*.18+body*TAU-rmsAc*.00015);
		float spiral2=spiral*spiral;
		float tend=spiral2*spiral2*spiral2*spiral*(.25+.75*ridge);
		float den=(.025+smoothstep(.58,.84,body+ridge*.18+tend*.3)*.24+tend*.75)*keep;
		if(den<.0001)continue;

		float energy=clamp(body*.18+ridge*.7+tend*1.4,0.,1.);
		float hue=fract(body*1.7+ridge*.43+ang*INV_TAU*.23+fz*.004+rmsAc*.000012);
		float alpha=1.-exp(-den*.34*step);
		// float sat=mix(.62,.96,energy),val=.16+1.12*energy;
		// vec3 hpv=abs(fract(vec3(fract(hue+time*.012))+vec3(0,2./3.,1./3.))*6.-3.);
		// vec3 fc=val*mix(vec3(1),clamp(hpv-1.,0.,1.),sat);
		float val=.1+.1*clamp(songDir*.5, 0.0, 20.0)*energy;
		vec3 fc=val*getBackgroundPalette(hue+time*.2);
		fc=mix(vec3(.002,.004,.018),fc,.18+.82*energy);
		f+=tr*fc*alpha*1.35*(.04+2.7*pow(energy,2.6));
		tr*=1.-alpha;
		if(tr<.03)break;
	}

	vec3 c=bkg*tr+f;
	if(hit)c=mix(c,surf,mix(.72,.96,p));
	c=max(c*.3+glow,vec3(0));
	fragColor=vec4(pow(c/(1.+c),vec3(1./1.8)),1);
}
