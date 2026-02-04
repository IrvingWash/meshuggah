#version 330 core

out vec4 fragmendColor;

in FragmentData
{
    vec4 color;
} fragmentData;

void main()
{
    fragmendColor = fragmentData.color;
}
