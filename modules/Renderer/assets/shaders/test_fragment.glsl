#version 330 core

struct Material
{
    sampler2D baseColorTexture;
    vec4 baseColor;
};

in FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

uniform Material uMaterial;

out vec4 fragmentColor;

void main()
{
    fragmentColor = texture(uMaterial.baseColorTexture, fragmentData.uv) * uMaterial.baseColor;
}
