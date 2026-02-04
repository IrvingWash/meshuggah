#version 330 core

in vec4 vColor;
out vec4 FragColor;

in FragmentData
{
    vec4 color;
} fragmentData;

void main()
{
    FragColor = fragmentData.color;
}
