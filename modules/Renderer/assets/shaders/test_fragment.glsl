#version 330 core

in FragmentData
{
    vec3 normal;
    vec2 uv;
} fragmentData;

out vec4 fragmentColor;

void main()
{
    fragmentColor = vec4(1);
}
