#version 330 core

struct Material
{
    sampler2D baseColor;
};

in FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

uniform vec4 uTint;

uniform Material uMaterial;

out vec4 fragmentColor;

void main()
{
    fragmentColor = texture(uMaterial.baseColor, fragmentData.uv) * uTint;
}
