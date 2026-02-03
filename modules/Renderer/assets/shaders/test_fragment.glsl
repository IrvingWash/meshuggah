#version 330 core

struct Material
{
    sampler2D baseColorTexture;
    vec4 baseColor;
};

struct AmbientLight
{
    vec3 color;
};

struct DirectionalLight
{
    vec3 direction;
    vec3 color;
};

in FragmentData
{
    vec3 normal;
    vec2 uv;
    vec4 tint;
} fragmentData;

uniform Material uMaterial;
uniform AmbientLight uAmbientLight;
uniform DirectionalLight uDirectionalLight;

out vec4 fragmentColor;

vec3 calculateDirectionalLight(
    DirectionalLight light,
    vec3 albedo,
    vec3 normalizedNormal
);

void main()
{
    vec3 normalizedNormal = normalize(fragmentData.normal);

    vec4 texelColor = texture(
        uMaterial.baseColorTexture,
        fragmentData.uv
    ) * uMaterial.baseColor * fragmentData.tint;

    vec3 albedo = texelColor.rgb;
    float alpha = texelColor.a;

    vec3 color = albedo * uAmbientLight.color;

    color += calculateDirectionalLight(
        uDirectionalLight,
        albedo,
        normalizedNormal
    );

    fragmentColor = vec4(color, alpha);
}

vec3 calculateDirectionalLight(
    DirectionalLight light,
    vec3 albedo,
    vec3 normalizedNormal
)
{
    vec3 lightDirection = normalize(-light.direction);

    // Diffuse
    float diff = max(dot(normalizedNormal, lightDirection), 0.0);
    vec3 diffuse = light.color * diff * albedo;

    return diffuse;
}
