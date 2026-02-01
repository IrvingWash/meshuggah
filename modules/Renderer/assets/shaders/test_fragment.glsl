#version 330 core

in FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

uniform vec4 uColor;

out vec4 fragmentColor;

void main()
{
    fragmentColor = uColor;
}
