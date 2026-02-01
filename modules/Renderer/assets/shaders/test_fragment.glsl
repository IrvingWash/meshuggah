#version 330 core

in FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

uniform vec4 uTint;

uniform sampler2D uBaseColor;

out vec4 fragmentColor;

void main()
{
    fragmentColor = texture(uBaseColor, fragmentData.uv) * uTint;
}
