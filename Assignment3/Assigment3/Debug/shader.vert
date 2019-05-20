#version 430

layout (location = 0) in vec3 v_vertex;	// vertex coordinates in model space
layout (location = 1) in vec3 v_normal;	// vertex normal in model space

out vec3 f_vertexInView;	// calculate lighting of vertex in camera space
out vec3 f_normalInView;	// calculate lighting of normal in camera space
out vec4 V_color;           // vertex lighting color

uniform mat4 um4p;	// projection matrix
uniform mat4 um4v;	// camera viewing transformation matrix
uniform mat4 um4n;	// model normalization matrix
uniform mat4 um4r;	// rotation matrix

struct LightInfo{
	vec4 position;
	vec4 spotDirection;
	vec4 La;			// Ambient light intensity
	vec4 Ld;			// Diffuse light intensity
	vec4 Ls;			// Specular light intensity
	float spotExponent;
	float spotCutoff;
	float constantAttenuation;
	float linearAttenuation;
	float quadraticAttenuation;
};

struct MaterialInfo
{
	vec4 Ka;
	vec4 Kd;
	vec4 Ks;
	float shininess;
};

uniform int lightIdx;			// Use this variable to contrl perpixel lighting mode
uniform int lightIdxv;			// Use this variable to contrl vertex lighting mode
uniform LightInfo light[3];
uniform MaterialInfo material;

vec4 directionalLight(vec3 N, vec3 V){
	// [TODO] same as fragment shader
	vec4 lightInView = um4p * um4v * light[0].position;	// the position of the light in camera space
	vec3 S = normalize(lightInView.xyz + V);		 
	vec3 H = normalize(S + V);						// Half vector

	float dc = dot(N, S);	
	float sc = pow(max(dot(N, H), 0), 64);

	return light[0].La * material.Ka + dc * light[0].Ld * material.Kd + sc * light[0].Ls * material.Ks;
}

vec4 pointLight(vec3 N, vec3 V){
	// [TODO] same as fragment shader
	vec4 lightInView = um4p * um4v * light[1].position;	// the position of the light in camera space
	vec3 S = normalize(lightInView.xyz + V);		 
	vec3 H = normalize(S + V);						// Half vector

	// [TODO] calculate diffuse coefficient and specular coefficient here
	float dc = dot(N,S) * light[1].quadraticAttenuation;	
	float sc = pow(max(dot(N, H), 0), 64) * light[1].quadraticAttenuation;

	return light[1].La * material.Ka + dc * light[1].Ld * material.Kd + sc * light[1].Ls * material.Ks;
}
vec4 spotLight(vec3 N, vec3 V){
	// [TODO] same as fragment shader
	vec4 lightInView = um4p * um4v * light[2].position;	// the position of the light in camera space
	vec3 S = normalize(lightInView.xyz + V);		// Normalized light source direction of point light source p
	vec3 H = normalize(S + V);						// Half vector

	// [TODO] calculate diffuse coefficient and specular coefficient here
	vec3 D = light[2].spotDirection.xyz;
	float angle = max(dot(D, S), 0); 
	if(angle > light[2].spotCutoff){
		float spotlight_effect = pow(angle, light[2].spotExponent);
		float dc = dot(N,S) * light[2].quadraticAttenuation * spotlight_effect;	
		float sc = pow(max(dot(N, H), 0), 64) * light[2].quadraticAttenuation * spotlight_effect;
		return light[2].La * material.Ka + dc * light[2].Ld * material.Kd + sc * light[2].Ls * material.Ks;
	}else{
		return vec4(0, 0, 0, 0);
	}
}

// To simplify the calculation, we do calculation for lighting in camera space 
void main() {
	
	// [TODO] transform vertex and normal into camera space
	// vec4 vertexInView = ? * ? * ? * vec4(v_vertex, 1.0);
	vec4 vertexInView = um4p * um4v * um4r * um4n * vec4(v_vertex, 1.0);
	// vec4 normalInView = transpose( inverse(? * ? * ?)) * vec4(v_normal, 0.0);
	vec4 normalInView = transpose( inverse(um4p * um4v * um4r * um4n)) * vec4(v_normal, 0.0);

	f_vertexInView = vertexInView.xyz;
	f_normalInView = normalInView.xyz;

	vec3 N = normalize(normalInView.xyz);		// N represents normalized normal of the model in camera space
	vec3 V = -vertexInView.xyz;					// V represents the vector from the vertex of the model to the camera position

	if(lightIdxv == 0)
	{
		V_color = directionalLight(N, V);
	}
	else if(lightIdxv == 1)
	{
		V_color = pointLight(N, V);
	}
	else if(lightIdxv == 2)
	{
		V_color = spotLight(N ,V);
	}
	
	gl_Position = um4p * um4v * um4r * um4n * vec4(v_vertex, 1.0);
}
